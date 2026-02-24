// Cards Screen - Credit and Debit card management
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/finance.dart';
import '../providers/finance_provider.dart';
import '../theme/app_theme.dart';

final _currencyFormat = NumberFormat('#,##0.00', 'en_US');

class CardsScreen extends StatelessWidget {
  const CardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, provider, _) {
        final creditCards = provider.creditCardsWithDebt;
        final debitCards = provider.debitCardsWithBalance;

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Credit Cards Section
                if (creditCards.isNotEmpty) ...[
                  _buildSectionHeader('💳 Crédito', AppTheme.credit),
                  const SizedBox(height: 8),
                  ...creditCards.map(
                    (item) => _CreditCardTile(card: item.card, debt: item.debt),
                  ),
                  const SizedBox(height: 20),
                ],

                // Debit Cards Section
                if (debitCards.isNotEmpty) ...[
                  _buildSectionHeader('🏦 Débito', AppTheme.income),
                  const SizedBox(height: 8),
                  ...debitCards.map(
                    (item) =>
                        _DebitCardTile(card: item.card, balance: item.balance),
                  ),
                  const SizedBox(height: 20),
                ],

                // Quick Actions — below the card sections, centered
                _buildQuickActions(context, provider),

                // Empty State
                if (creditCards.isEmpty && debitCards.isEmpty)
                  _buildEmptyState(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, FinanceProvider provider) {
    final hasDebit = provider.cards.any((c) => c.isDebit);
    final hasCredit = provider.creditCardsWithDebt.any((c) => c.debt > 0);

    if (!hasCredit && !hasDebit) return const SizedBox.shrink();

    return Center(
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          if (hasCredit)
            _QuickActionChip(
              icon: '💳',
              label: 'Pagar tarjeta',
              color: AppTheme.credit,
              onTap: () => _showPayCreditDialog(context, provider),
            ),
          if (hasDebit)
            _QuickActionChip(
              icon: '🔄',
              label: 'Transferir',
              color: Colors.blue,
              onTap: () => _showTransferDialog(context, provider),
            ),
        ],
      ),
    );
  }

  // ─── Transfer Dialog (cash→debit or debit→debit) ───
  void _showTransferDialog(BuildContext context, FinanceProvider provider) {
    final debitCards = provider.cards.where((c) => c.isDebit).toList();
    if (debitCards.isEmpty) return;

    String sourceMethod = 'cash';
    String? targetCardId = debitCards.first.id;
    final amountController = TextEditingController();

    // Source options: cash + all debit cards
    final sourceOptions = <({String id, String label})>[
      (id: 'cash', label: '💵 Efectivo'),
      ...debitCards.map((c) => (id: c.id, label: '${c.colorEmoji} ${c.name}')),
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          // Filter target: can't transfer to same card
          final availableTargets = debitCards
              .where((c) => c.id != sourceMethod)
              .toList();
          if (availableTargets.isNotEmpty &&
              !availableTargets.any((c) => c.id == targetCardId)) {
            targetCardId = availableTargets.first.id;
          }

          return AlertDialog(
            title: const Text('🔄 Transferir'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Source selector
                DropdownButtonFormField<String>(
                  initialValue: sourceMethod,
                  decoration: const InputDecoration(
                    labelText: 'Desde',
                    border: OutlineInputBorder(),
                  ),
                  items: sourceOptions
                      .map(
                        (s) =>
                            DropdownMenuItem(value: s.id, child: Text(s.label)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => sourceMethod = v ?? 'cash'),
                ),
                const SizedBox(height: 12),
                // Target selector
                DropdownButtonFormField<String>(
                  initialValue: targetCardId,
                  decoration: const InputDecoration(
                    labelText: 'Hacia',
                    border: OutlineInputBorder(),
                  ),
                  items: availableTargets
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text('${c.colorEmoji} ${c.name}'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => targetCardId = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Monto',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  final amount = double.tryParse(amountController.text);
                  if (amount != null && amount > 0 && targetCardId != null) {
                    provider.addTransfer(
                      amount: amount,
                      targetCardId: targetCardId!,
                      sourcePaymentMethod: sourceMethod,
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '✅ \$${_currencyFormat.format(amount)} transferido',
                        ),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  }
                },
                child: const Text('Transferir'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Pay Credit Dialog (from cash or debit) ───
  void _showPayCreditDialog(BuildContext context, FinanceProvider provider) {
    final cardsWithDebt = provider.creditCardsWithDebt
        .where((c) => c.debt > 0)
        .toList();
    if (cardsWithDebt.isEmpty) return;

    final debitCards = provider.cards.where((c) => c.isDebit).toList();

    String? selectedCardId = cardsWithDebt.first.card.id;
    String sourceMethod = 'cash';
    final amountController = TextEditingController();

    // Source options: cash + debit cards
    final sourceOptions = <({String id, String label})>[
      (id: 'cash', label: '💵 Efectivo'),
      ...debitCards.map((c) => (id: c.id, label: '${c.colorEmoji} ${c.name}')),
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final selectedDebt = cardsWithDebt
              .where((c) => c.card.id == selectedCardId)
              .firstOrNull
              ?.debt;

          return AlertDialog(
            title: const Text('💳 Pagar Tarjeta'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Credit card to pay
                DropdownButtonFormField<String>(
                  initialValue: selectedCardId,
                  decoration: const InputDecoration(
                    labelText: 'Tarjeta',
                    border: OutlineInputBorder(),
                  ),
                  items: cardsWithDebt
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.card.id,
                          child: Text(
                            '${c.card.colorEmoji} ${c.card.name} (-\$${_currencyFormat.format(c.debt)})',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => selectedCardId = v),
                ),
                const SizedBox(height: 12),
                // Source: cash or debit
                DropdownButtonFormField<String>(
                  initialValue: sourceMethod,
                  decoration: const InputDecoration(
                    labelText: 'Pagar desde',
                    border: OutlineInputBorder(),
                  ),
                  items: sourceOptions
                      .map(
                        (s) =>
                            DropdownMenuItem(value: s.id, child: Text(s.label)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => sourceMethod = v ?? 'cash'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Monto',
                    prefixText: '\$ ',
                    border: const OutlineInputBorder(),
                    helperText: selectedDebt != null
                        ? 'Deuda: \$${_currencyFormat.format(selectedDebt)}'
                        : null,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  final amount = double.tryParse(amountController.text);
                  if (amount != null && amount > 0 && selectedCardId != null) {
                    provider.addTransaction(
                      amount: amount,
                      type: TransactionType.creditPayment,
                      categoryId: 'credit-payment',
                      paymentMethod: sourceMethod,
                      targetCardId: selectedCardId,
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '✅ Pago de \$${_currencyFormat.format(amount)}',
                        ),
                        backgroundColor: AppTheme.income,
                      ),
                    );
                  }
                },
                child: const Text('Pagar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(48),
        child: Column(
          children: [
            Text('💳', style: TextStyle(fontSize: 48)),
            SizedBox(height: 16),
            Text(
              'No hay tarjetas',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Agrega tarjetas en Ajustes',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Credit Card Tile ---
class _CreditCardTile extends StatelessWidget {
  final dynamic card; // FinanceCard
  final double debt;

  const _CreditCardTile({required this.card, required this.debt});

  @override
  Widget build(BuildContext context) {
    final hasDebt = debt > 0;
    final limit = card.creditLimit;
    final usagePercent = limit != null && limit > 0
        ? (debt / limit).clamp(0.0, 1.0)
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: AppTheme.credit.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppTheme.credit.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(card.colorEmoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (card.cutOffDay != null && card.paymentDay != null)
                        Text(
                          'Corte: ${card.cutOffDay} • Pago: ${card.paymentDay}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      hasDebt
                          ? '-\$${_currencyFormat.format(debt)}'
                          : 'Al corriente',
                      style: TextStyle(
                        color: hasDebt ? AppTheme.expense : AppTheme.income,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (limit != null)
                      Text(
                        'Límite: \$${_currencyFormat.format(limit)}',
                        style: TextStyle(color: Colors.grey[400], fontSize: 11),
                      ),
                  ],
                ),
              ],
            ),
            // Usage bar
            if (usagePercent != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: usagePercent,
                  minHeight: 6,
                  backgroundColor: Colors.grey[800],
                  color: usagePercent > 0.8
                      ? AppTheme.expense
                      : usagePercent > 0.5
                      ? Colors.orange
                      : AppTheme.income,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(usagePercent * 100).toStringAsFixed(0)}% utilizado',
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// --- Debit Card Tile ---
class _DebitCardTile extends StatelessWidget {
  final dynamic card; // FinanceCard
  final double balance;

  const _DebitCardTile({required this.card, required this.balance});

  @override
  Widget build(BuildContext context) {
    final isPositive = balance >= 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: AppTheme.income.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppTheme.income.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(card.colorEmoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                card.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Text(
              '\$${_currencyFormat.format(balance.abs())}',
              style: TextStyle(
                color: isPositive ? AppTheme.income : AppTheme.expense,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Quick Action Chip ---
class _QuickActionChip extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Text(icon, style: const TextStyle(fontSize: 16)),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
    );
  }
}
