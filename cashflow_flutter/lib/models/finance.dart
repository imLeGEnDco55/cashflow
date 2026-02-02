/// Data models for CashFlow finance app
/// Translated from TypeScript types/finance.ts
library;

import 'package:uuid/uuid.dart';

const _uuid = Uuid();

// Transaction types
enum TransactionType {
  income, // Money coming in (+balance)
  expense, // Money going out via cash/debit (-balance)
  creditExpense, // Purchase with credit card (NO balance change, +card debt)
  creditPayment, // Paying off credit card (-balance, -card debt)
}

// Card colors (emoji-based)
const List<String> cardColors = [
  '🟥',
  '🟧',
  '🟨',
  '🟩',
  '🟦',
  '🟪',
  '🟫',
  '⬛',
  '⬜',
];

/// Category model
class FinanceCategory {
  final String id;
  final String emoji;
  final String description;
  final bool isSuperEmoji;
  final String? aliases; // Comma-separated alternative names for search

  FinanceCategory({
    String? id,
    required this.emoji,
    required this.description,
    this.isSuperEmoji = false,
    this.aliases,
  }) : id = id ?? _uuid.v4();

  /// Get all searchable terms (description + aliases)
  List<String> get searchTerms {
    final terms = [description.toLowerCase()];
    if (aliases != null && aliases!.isNotEmpty) {
      terms.addAll(aliases!.split(',').map((s) => s.trim().toLowerCase()));
    }
    return terms;
  }

  /// Check if category matches a search query
  bool matchesSearch(String query) {
    final q = query.toLowerCase();
    return searchTerms.any((term) => term.contains(q));
  }

  FinanceCategory copyWith({
    String? emoji,
    String? description,
    bool? isSuperEmoji,
    String? aliases,
  }) {
    return FinanceCategory(
      id: id,
      emoji: emoji ?? this.emoji,
      description: description ?? this.description,
      isSuperEmoji: isSuperEmoji ?? this.isSuperEmoji,
      aliases: aliases ?? this.aliases,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'emoji': emoji,
    'description': description,
    'isSuperEmoji': isSuperEmoji,
    if (aliases != null) 'aliases': aliases,
  };

  factory FinanceCategory.fromJson(Map<String, dynamic> json) =>
      FinanceCategory(
        id: json['id'] as String,
        emoji: json['emoji'] as String,
        description: json['description'] as String,
        isSuperEmoji: json['isSuperEmoji'] as bool? ?? false,
        aliases: json['aliases'] as String?,
      );
}

/// Finance Card model (credit or debit)
class FinanceCard {
  final String id;
  final String name;
  final String type; // 'credit' | 'debit'
  final String colorEmoji;
  final int? cutOffDay; // For credit cards only (1-31)
  final int? paymentDay; // For credit cards only (1-31)

  FinanceCard({
    String? id,
    required this.name,
    required this.type,
    required this.colorEmoji,
    this.cutOffDay,
    this.paymentDay,
  }) : id = id ?? _uuid.v4();

  FinanceCard copyWith({
    String? name,
    String? type,
    String? colorEmoji,
    int? cutOffDay,
    int? paymentDay,
  }) {
    return FinanceCard(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      colorEmoji: colorEmoji ?? this.colorEmoji,
      cutOffDay: cutOffDay ?? this.cutOffDay,
      paymentDay: paymentDay ?? this.paymentDay,
    );
  }

  bool get isCredit => type == 'credit';

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'colorEmoji': colorEmoji,
    if (cutOffDay != null) 'cutOffDay': cutOffDay,
    if (paymentDay != null) 'paymentDay': paymentDay,
  };

  factory FinanceCard.fromJson(Map<String, dynamic> json) => FinanceCard(
    id: json['id'] as String,
    name: json['name'] as String,
    type: json['type'] as String,
    colorEmoji: json['colorEmoji'] as String,
    cutOffDay: json['cutOffDay'] as int?,
    paymentDay: json['paymentDay'] as int?,
  );
}

/// Sub-emoji item for Superemoji breakdown
class SubEmojiItem {
  final String categoryId;
  final double amount;

  SubEmojiItem({required this.categoryId, required this.amount});

  Map<String, dynamic> toJson() => {'categoryId': categoryId, 'amount': amount};

  factory SubEmojiItem.fromJson(Map<String, dynamic> json) => SubEmojiItem(
    categoryId: json['categoryId'] as String,
    amount: (json['amount'] as num).toDouble(),
  );
}

/// Transaction model
class Transaction {
  final String id;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final String paymentMethod; // 'cash' or card id
  final DateTime date;
  final int createdAt; // timestamp
  final String? targetCardId; // For credit_payment
  final List<SubEmojiItem>? breakdown; // Superemoji breakdown
  final bool isRecurring; // Fixed/recurring transaction (e.g. salary)

  Transaction({
    String? id,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.paymentMethod,
    DateTime? date,
    int? createdAt,
    this.targetCardId,
    this.breakdown,
    this.isRecurring = false,
  }) : id = id ?? _uuid.v4(),
       date = date ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  Transaction copyWith({
    double? amount,
    String? categoryId,
    List<SubEmojiItem>? breakdown,
    bool? isRecurring,
  }) {
    return Transaction(
      id: id,
      amount: amount ?? this.amount,
      type: type,
      categoryId: categoryId ?? this.categoryId,
      paymentMethod: paymentMethod,
      date: date,
      createdAt: createdAt,
      targetCardId: targetCardId,
      breakdown: breakdown ?? this.breakdown,
      isRecurring: isRecurring ?? this.isRecurring,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'type': type.name,
    'categoryId': categoryId,
    'paymentMethod': paymentMethod,
    'date': date.toIso8601String(),
    'createdAt': createdAt,
    if (targetCardId != null) 'targetCardId': targetCardId,
    if (breakdown != null)
      'breakdown': breakdown!.map((b) => b.toJson()).toList(),
    'isRecurring': isRecurring,
  };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'] as String,
    amount: (json['amount'] as num).toDouble(),
    type: TransactionType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => TransactionType.expense,
    ),
    categoryId: json['categoryId'] as String,
    paymentMethod: json['paymentMethod'] as String,
    date: DateTime.parse(json['date'] as String),
    createdAt: json['createdAt'] as int,
    targetCardId: json['targetCardId'] as String?,
    breakdown: json['breakdown'] != null
        ? (json['breakdown'] as List)
              .map((b) => SubEmojiItem.fromJson(b as Map<String, dynamic>))
              .toList()
        : null,
    isRecurring: json['isRecurring'] as bool? ?? false,
  );
}

/// Finance data container
class FinanceData {
  final List<FinanceCategory> categories;
  final List<FinanceCard> cards;
  final List<Transaction> transactions;

  FinanceData({
    required this.categories,
    required this.cards,
    required this.transactions,
  });

  Map<String, dynamic> toJson() => {
    'categories': categories.map((c) => c.toJson()).toList(),
    'cards': cards.map((c) => c.toJson()).toList(),
    'transactions': transactions.map((t) => t.toJson()).toList(),
  };

  factory FinanceData.fromJson(Map<String, dynamic> json) => FinanceData(
    categories: (json['categories'] as List)
        .map((c) => FinanceCategory.fromJson(c as Map<String, dynamic>))
        .toList(),
    cards: (json['cards'] as List)
        .map((c) => FinanceCard.fromJson(c as Map<String, dynamic>))
        .toList(),
    transactions: (json['transactions'] as List)
        .map((t) => Transaction.fromJson(t as Map<String, dynamic>))
        .toList(),
  );
}

/// Default categories (only credit-payment is required)
final List<FinanceCategory> defaultCategories = [
  FinanceCategory(
    id: 'credit-payment',
    emoji: '💳',
    description: 'Pago de tarjeta',
  ),
];
