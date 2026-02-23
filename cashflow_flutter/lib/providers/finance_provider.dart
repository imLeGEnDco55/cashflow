/// Finance Provider - State management and persistence
/// Translated from useFinanceData.ts
library;

import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/finance.dart';
import '../services/notification_service.dart';
import '../services/database_service.dart';

const String _storageKey = 'emoji-finance-data';

class FinanceProvider extends ChangeNotifier {
  List<FinanceCategory> _categories = List.from(defaultCategories);
  List<FinanceCard> _cards = [];
  List<Transaction> _transactions = [];
  List<Budget> _budgets = [];
  bool _remindersEnabled = false;

  bool _isLoading = true;

  // Getters
  List<FinanceCategory> get categories => List.unmodifiable(_categories);
  List<FinanceCard> get cards => List.unmodifiable(_cards);
  List<Transaction> get transactions => List.unmodifiable(_transactions);
  List<Budget> get budgets => List.unmodifiable(_budgets);
  bool get remindersEnabled => _remindersEnabled;
  bool get isLoading => _isLoading;

  /// Balance calculation:
  /// + income
  /// - expense (cash/debit)
  /// - credit_payment (when you pay off credit card)
  /// credit_expense does NOT affect balance
  double get balance {
    return _transactions.fold(0.0, (acc, t) {
      switch (t.type) {
        case TransactionType.income:
          return acc + t.amount;
        case TransactionType.expense:
        case TransactionType.creditPayment:
          return acc - t.amount;
        case TransactionType.creditExpense:
          return acc; // No balance change
      }
    });
  }

  /// Calculate debts for all cards
  Map<String, double> get _debtsByCard {
    final debts = <String, double>{};
    for (final t in _transactions) {
      if (t.type == TransactionType.creditExpense) {
        debts[t.paymentMethod] = (debts[t.paymentMethod] ?? 0) + t.amount;
      }
      if (t.type == TransactionType.creditPayment && t.targetCardId != null) {
        debts[t.targetCardId!] = (debts[t.targetCardId!] ?? 0) - t.amount;
      }
    }
    return debts;
  }

  /// Get debt for a specific card
  double getCardDebt(String cardId) => _debtsByCard[cardId] ?? 0;

  /// Total credit debt across all cards
  double get totalCreditDebt {
    return _cards
        .where((c) => c.isCredit)
        .fold(
          0.0,
          (total, card) =>
              total + (getCardDebt(card.id).clamp(0, double.infinity)),
        );
  }

  /// Credit cards with their current debt
  List<({FinanceCard card, double debt})> get creditCardsWithDebt {
    return _cards
        .where((c) => c.isCredit)
        .map(
          (card) => (
            card: card,
            debt: getCardDebt(card.id).clamp(0.0, double.infinity).toDouble(),
          ),
        )
        .toList();
  }

  /// Get category by id
  FinanceCategory? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get card by id
  FinanceCard? getCardById(String id) {
    try {
      return _cards.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  // ============ MUTATIONS ============

  /// Add a new transaction
  void addTransaction({
    required double amount,
    required TransactionType type,
    required String categoryId,
    required String paymentMethod,
    String? targetCardId,
  }) {
    final transaction = Transaction(
      amount: amount,
      type: type,
      categoryId: categoryId,
      paymentMethod: paymentMethod,
      targetCardId: targetCardId,
    );
    _transactions.insert(0, transaction);
    notifyListeners();
    DatabaseService.instance.insertTransaction(transaction);
  }

  /// Delete a transaction
  void deleteTransaction(String id) {
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();
    DatabaseService.instance.deleteTransaction(id);
  }

  /// Update transaction breakdown (for Superemoji detail)
  void updateTransactionBreakdown(String id, List<SubEmojiItem> breakdown) {
    final index = _transactions.indexWhere((t) => t.id == id);
    if (index != -1) {
      _transactions[index] = _transactions[index].copyWith(
        breakdown: breakdown,
      );
      notifyListeners();
      DatabaseService.instance.updateTransaction(_transactions[index]);
    }
  }

  /// Update transaction category
  void updateTransactionCategory(String id, String newCategoryId) {
    final index = _transactions.indexWhere((t) => t.id == id);
    if (index != -1) {
      _transactions[index] = _transactions[index].copyWith(
        categoryId: newCategoryId,
      );
      notifyListeners();
      DatabaseService.instance.updateTransaction(_transactions[index]);
    }
  }

  /// Update transaction amount
  void updateTransactionAmount(String id, double newAmount) {
    final index = _transactions.indexWhere((t) => t.id == id);
    if (index != -1) {
      _transactions[index] = _transactions[index].copyWith(amount: newAmount);
      notifyListeners();
      DatabaseService.instance.updateTransaction(_transactions[index]);
    }
  }

  /// Toggle transaction recurring status
  void toggleTransactionRecurring(String id) {
    final index = _transactions.indexWhere((t) => t.id == id);
    if (index != -1) {
      _transactions[index] = _transactions[index].copyWith(
        isRecurring: !_transactions[index].isRecurring,
      );
      notifyListeners();
      DatabaseService.instance.updateTransaction(_transactions[index]);
    }
  }

  /// Add a new category
  void addCategory({
    required String emoji,
    required String description,
    bool isSuperEmoji = false,
    String type = 'expense',
    String? aliases,
  }) {
    if (_categories.any(
      (c) => c.description.toLowerCase() == description.toLowerCase(),
    )) {
      throw Exception('Ya existe una categoría con ese nombre');
    }
    final category = FinanceCategory(
      emoji: emoji,
      description: description,
      isSuperEmoji: isSuperEmoji,
      type: type,
      aliases: aliases,
    );
    _categories.add(category);
    notifyListeners();
    _saveData();
  }

  /// Update a category
  void updateCategory(
    String id, {
    String? emoji,
    String? description,
    bool? isSuperEmoji,
    String? type,
    String? aliases,
  }) {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index != -1) {
      _categories[index] = _categories[index].copyWith(
        emoji: emoji,
        description: description,
        isSuperEmoji: isSuperEmoji,
        type: type,
        aliases: aliases,
      );
      notifyListeners();
      _saveData();
    }
  }

  /// Delete a category
  void deleteCategory(String id) {
    _categories.removeWhere((c) => c.id == id);
    notifyListeners();
    _saveData();
  }

  /// Add a new card
  void addCard({
    required String name,
    required String type,
    required String colorEmoji,
    int? cutOffDay,
    int? paymentDay,
  }) {
    if (_cards.any((c) => c.name.toLowerCase() == name.toLowerCase())) {
      throw Exception('Ya existe una tarjeta con ese nombre');
    }
    if (type == 'credit') {
      if (cutOffDay == null || cutOffDay < 1 || cutOffDay > 31) {
        throw Exception('Día de corte inválido (1-31)');
      }
      if (paymentDay == null || paymentDay < 1 || paymentDay > 31) {
        throw Exception('Día de pago inválido (1-31)');
      }
    }

    final card = FinanceCard(
      name: name,
      type: type,
      colorEmoji: colorEmoji,
      cutOffDay: cutOffDay,
      paymentDay: paymentDay,
    );
    _cards.add(card);
    notifyListeners();
    _saveData();
  }

  /// Update a card
  void updateCard(
    String id, {
    String? name,
    String? type,
    String? colorEmoji,
    int? cutOffDay,
    int? paymentDay,
  }) {
    final index = _cards.indexWhere((c) => c.id == id);
    if (index != -1) {
      _cards[index] = _cards[index].copyWith(
        name: name,
        type: type,
        colorEmoji: colorEmoji,
        cutOffDay: cutOffDay,
        paymentDay: paymentDay,
      );
      notifyListeners();
      _saveData();
    }
  }

  /// Delete a card
  void deleteCard(String id) {
    _cards.removeWhere((c) => c.id == id);
    notifyListeners();
    _saveData();
  }

  /// Check if category can be safely deleted
  bool canDeleteCategory(String id) {
    return !_transactions.any((t) => t.categoryId == id);
  }

  /// Check if card can be safely deleted
  bool canDeleteCard(String id) {
    return !_transactions.any(
      (t) => t.paymentMethod == id || t.targetCardId == id,
    );
  }

  /// Add or update a budget
  void setBudget(String categoryId, double limit) {
    final index = _budgets.indexWhere((b) => b.categoryId == categoryId);
    if (limit <= 0) {
      if (index != -1) {
        final catId = _budgets[index].categoryId;
        _budgets.removeAt(index);
        DatabaseService.instance.deleteBudget(catId);
      }
    } else {
      final budget = Budget(categoryId: categoryId, limit: limit);
      if (index != -1) {
        _budgets[index] = budget;
      } else {
        _budgets.add(budget);
      }
      DatabaseService.instance.updateBudget(budget);
    }
    notifyListeners();
  }

  /// Get budget for a category
  Budget? getBudgetForCategory(String categoryId) {
    try {
      return _budgets.firstWhere((b) => b.categoryId == categoryId);
    } catch (_) {
      return null;
    }
  }

  /// Toggle reminders
  void toggleReminders(bool enabled) async {
    _remindersEnabled = enabled;
    if (enabled) {
      await NotificationService.schedulePaymentReminders(_cards);
    } else {
      await NotificationService.schedulePaymentReminders([]);
    }
    notifyListeners();
    DatabaseService.instance.setSetting(
      'reminders_enabled',
      enabled.toString(),
    );
  }

  // ============ PERSISTENCE ============

  /// Load data from SharedPreferences or SQLite
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();
    await NotificationService.init();

    try {
      final db = DatabaseService.instance;
      final isMigrated = await db.getSetting('is_migrated');

      if (isMigrated == 'true') {
        _categories = await db.getCategories();
        _cards = await db.getCards();
        _transactions = await db.getTransactions();
        _budgets = await db.getBudgets();
        final rem = await db.getSetting('reminders_enabled');
        _remindersEnabled = rem == 'true';
      } else {
        // Migration from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final stored = prefs.getString(_storageKey);

        if (stored != null) {
          final data = FinanceData.fromJson(jsonDecode(stored));
          _categories = data.categories.isNotEmpty
              ? data.categories
              : List.from(defaultCategories);
          _cards = data.cards;
          _transactions = data.transactions;
          _budgets = data.budgets;
          _remindersEnabled = data.remindersEnabled;

          // Save to SQLite
          await db.saveCategories(_categories);
          await db.saveCards(_cards);
          await db.saveTransactions(_transactions);
          await db.saveBudgets(_budgets);
          await db.setSetting(
            'reminders_enabled',
            _remindersEnabled.toString(),
          );
        } else {
          // New user, save defaults to SQLite
          await db.saveCategories(_categories);
          await db.setSetting('reminders_enabled', 'false');
        }
        await db.setSetting('is_migrated', 'true');
      }

      if (_remindersEnabled) {
        await NotificationService.schedulePaymentReminders(_cards);
      }
    } catch (e) {
      debugPrint('Error loading finance data: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Save core data to SQLite
  Future<void> _saveData() async {
    try {
      final db = DatabaseService.instance;
      await db.saveCategories(_categories);
      await db.saveCards(_cards);
      await db.saveTransactions(_transactions);
      await db.saveBudgets(_budgets);
      await db.setSetting('reminders_enabled', _remindersEnabled.toString());
    } catch (e) {
      debugPrint('Error saving finance data: $e');
    }
  }

  /// Export data as JSON string
  String exportData() {
    final data = FinanceData(
      categories: _categories,
      cards: _cards,
      transactions: _transactions,
      budgets: _budgets,
      remindersEnabled: _remindersEnabled,
    );
    return const JsonEncoder.withIndent('  ').convert(data.toJson());
  }

  /// Import data from JSON string
  bool importData(String jsonString) {
    try {
      final data = FinanceData.fromJson(jsonDecode(jsonString));
      _categories = data.categories;
      _cards = data.cards;
      _transactions = data.transactions;
      _budgets = data.budgets;
      _remindersEnabled = data.remindersEnabled;
      notifyListeners();
      _saveData(); // Correctly implemented to save to DB
      if (_remindersEnabled) {
        NotificationService.schedulePaymentReminders(_cards);
      }
      return true;
    } catch (e) {
      debugPrint('Error importing data: $e');
      return false;
    }
  }

  /// Export transactions to CSV and share
  Future<void> exportToCSV() async {
    final List<List<dynamic>> rows = [];
    rows.add([
      'Fecha',
      'Categoría',
      'Monto',
      'Tipo',
      'Método Pago',
      'Desglose',
    ]);

    for (var t in _transactions) {
      final category =
          getCategoryById(t.categoryId)?.description ?? 'Desconocida';
      final paymentMethod = t.paymentMethod == 'cash'
          ? 'Efectivo'
          : (getCardById(t.paymentMethod)?.name ?? 'Tarjeta borrada');

      String breakdownStr = '';
      if (t.breakdown != null && t.breakdown!.isNotEmpty) {
        breakdownStr = t.breakdown!
            .map((b) {
              final cat = getCategoryById(b.categoryId)?.description ?? '?';
              return '$cat: \$${b.amount}';
            })
            .join('; ');
      }

      rows.add([
        t.date.toIso8601String().split('T')[0],
        category,
        t.amount,
        t.type.name,
        paymentMethod,
        breakdownStr,
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);

    // For Android/iOS
    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        'cashflow_export_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(csv);

    await Share.shareXFiles([XFile(file.path)], text: 'CashFlow CSV Export');
  }
}
