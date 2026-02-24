// Transaction Card Widget - Reusable transaction display
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/finance.dart';
import '../theme/app_theme.dart';

final _currencyFormat = NumberFormat('#,##0.00', 'en_US');

class TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final FinanceCategory? category;
  final FinanceCard? card;
  final List<FinanceCategory> categories;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.category,
    this.card,
    this.categories = const [],
  });

  Color get _amountColor {
    switch (transaction.type) {
      case TransactionType.income:
        return AppTheme.income;
      case TransactionType.expense:
      case TransactionType.creditPayment:
        return AppTheme.expense;
      case TransactionType.creditExpense:
        return AppTheme.credit;
    }
  }

  Color get _cardTint {
    switch (transaction.type) {
      case TransactionType.income:
        return AppTheme.income;
      case TransactionType.expense:
      case TransactionType.creditPayment:
        return AppTheme.expense;
      case TransactionType.creditExpense:
        return AppTheme.credit;
    }
  }

  String get _prefix {
    switch (transaction.type) {
      case TransactionType.income:
        return '+';
      case TransactionType.expense:
      case TransactionType.creditPayment:
        return '-';
      case TransactionType.creditExpense:
        return '💳 ';
    }
  }

  String get _paymentMethod {
    if (transaction.type == TransactionType.creditPayment) {
      return 'Pago tarjeta';
    }
    if (transaction.paymentMethod == 'cash') {
      return '💵 Efectivo';
    }
    return card != null ? '${card!.colorEmoji} ${card!.name}' : '💳';
  }

  String? get _badge {
    switch (transaction.type) {
      case TransactionType.creditExpense:
        return 'CRÉDITO';
      case TransactionType.creditPayment:
        return 'PAGO';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM', 'es');
    final isSuperEmoji = category?.isSuperEmoji ?? false;
    final hasBreakdown =
        transaction.breakdown != null && transaction.breakdown!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: _cardTint.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _cardTint.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Emoji
                Stack(
                  children: [
                    Text(
                      category?.emoji ?? '❓',
                      style: const TextStyle(fontSize: 36),
                    ),
                    if (isSuperEmoji)
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: AppTheme.secondary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.star,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              category?.description ?? 'Desconocido',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.credit.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _badge!,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.credit,
                                ),
                              ),
                            ),
                          ],
                          if (transaction.isRecurring) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.repeat,
                              size: 14,
                              color: AppTheme.income.withValues(alpha: 0.7),
                            ),
                          ],
                          if (isSuperEmoji && !hasBreakdown) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.secondary.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '📝 DETALLAR',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.secondary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${dateFormat.format(transaction.date)} • $_paymentMethod',
                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                      ),
                    ],
                  ),
                ),

                // Amount
                Text(
                  '$_prefix\$${_currencyFormat.format(transaction.amount)}',
                  style: TextStyle(
                    color: _amountColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),

            // Breakdown row (if exists)
            if (hasBreakdown) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 6),
              ...transaction.breakdown!
                  .where((item) {
                    // Hide income categories from breakdown
                    final subCat = categories.isEmpty
                        ? null
                        : categories.cast<FinanceCategory?>().firstWhere(
                            (c) => c!.id == item.categoryId,
                            orElse: () => null,
                          );
                    return subCat == null || !subCat.isIncome;
                  })
                  .map((item) {
                    final subCat = categories.isEmpty
                        ? null
                        : categories.cast<FinanceCategory?>().firstWhere(
                            (c) => c!.id == item.categoryId,
                            orElse: () => null,
                          );
                    return Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 2),
                      child: Row(
                        children: [
                          Text(
                            subCat?.emoji ?? '❓',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              subCat?.description ?? '?',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[400],
                              ),
                            ),
                          ),
                          Text(
                            '\$${_currencyFormat.format(item.amount)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[300],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
            ],
          ],
        ),
      ),
    );
  }
}
