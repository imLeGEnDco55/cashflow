/// Finance Provider - State management and persistence
/// Translated from useFinanceData.ts
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/finance.dart';

const String _storageKey = 'emoji-finance-data';

class FinanceProvider extends ChangeNotifier {
  List<FinanceCategory> _categories = List.from(defaultCategories);
  List<FinanceCard> _cards = [];
  List<Transaction> _transactions = [];

  bool _isLoading = true;

  // Getters
  List<FinanceCategory> get categories => List.unmodifiable(_categories);
  List<FinanceCard> get cards => List.unmodifiable(_cards);
  List<Transaction> get transactions => List.unmodifiable(_transactions);
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
    _saveData();
  }

  /// Delete a transaction
  void deleteTransaction(String id) {
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();
    _saveData();
  }

  /// Update transaction breakdown (for Superemoji detail)
  void updateTransactionBreakdown(String id, List<SubEmojiItem> breakdown) {
    final index = _transactions.indexWhere((t) => t.id == id);
    if (index != -1) {
      _transactions[index] = _transactions[index].copyWith(
        breakdown: breakdown,
      );
      notifyListeners();
      _saveData();
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
      _saveData();
    }
  }

  /// Update transaction amount
  void updateTransactionAmount(String id, double newAmount) {
    final index = _transactions.indexWhere((t) => t.id == id);
    if (index != -1) {
      _transactions[index] = _transactions[index].copyWith(amount: newAmount);
      notifyListeners();
      _saveData();
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
      _saveData();
    }
  }

  /// Add a new category
  void addCategory({
    required String emoji,
    required String description,
    bool isSuperEmoji = false,
    String? aliases,
  }) {
    final category = FinanceCategory(
      emoji: emoji,
      description: description,
      isSuperEmoji: isSuperEmoji,
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
    String? aliases,
  }) {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index != -1) {
      _categories[index] = _categories[index].copyWith(
        emoji: emoji,
        description: description,
        isSuperEmoji: isSuperEmoji,
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

  // ============ PERSISTENCE ============

  /// Load data from SharedPreferences
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_storageKey);

      if (stored != null) {
        final data = FinanceData.fromJson(jsonDecode(stored));
        _categories = data.categories.isNotEmpty
            ? data.categories
            : List.from(defaultCategories);
        _cards = data.cards;
        _transactions = data.transactions;
      }
    } catch (e) {
      debugPrint('Error loading finance data: $e');
      // Keep defaults on error
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Save data to SharedPreferences (debounced internally via isolate)
  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = FinanceData(
        categories: _categories,
        cards: _cards,
        transactions: _transactions,
      );
      await prefs.setString(_storageKey, jsonEncode(data.toJson()));
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
      notifyListeners();
      _saveData();
      return true;
    } catch (e) {
      debugPrint('Error importing data: $e');
      return false;
    }
  }
}
