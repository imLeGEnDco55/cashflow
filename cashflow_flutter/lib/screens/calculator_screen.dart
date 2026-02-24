// Calculator Screen - Balanced layout, internal scrolling for categories

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/finance.dart';
import '../providers/finance_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/stagger_animation.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _amountController = TextEditingController();
  final _searchController = TextEditingController();
  TransactionType _transactionType = TransactionType.expense;
  String? _selectedCategoryId;
  String _searchQuery = '';

  @override
  void dispose() {
    _amountController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleSubmit(String paymentMethod) {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0 || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa monto y categoría')),
      );
      return;
    }

    final provider = context.read<FinanceProvider>();
    TransactionType actualType = _transactionType;
    if (_transactionType == TransactionType.expense &&
        paymentMethod != 'cash') {
      final card = provider.getCardById(paymentMethod);
      if (card?.isCredit == true) {
        actualType = TransactionType.creditExpense;
      }
    }

    provider.addTransaction(
      amount: amount,
      type: actualType,
      categoryId: _selectedCategoryId!,
      paymentMethod: paymentMethod,
    );

    _amountController.clear();
    _searchController.clear();
    setState(() {
      _selectedCategoryId = null;
      _searchQuery = '';
    });

    // Close dialog if open
    Navigator.pop(context);

    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          actualType == TransactionType.income
              ? '✅ Ingreso registrado'
              : actualType == TransactionType.creditExpense
              ? '✅ Gasto crédito (sin afectar balance)'
              : '✅ Gasto registrado',
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: actualType == TransactionType.income
            ? AppTheme.income
            : actualType == TransactionType.creditExpense
            ? AppTheme.credit
            : AppTheme.expense,
      ),
    );
  }

  void _showPaymentOptions(FinanceProvider provider) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppTheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Método de Pago',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _PayOption(
                emoji: '💵',
                label: 'Efectivo',
                onTap: () => _handleSubmit('cash'),
              ),
              // Filter: hide credit cards when registering income
              ...provider.cards
                  .where(
                    (card) =>
                        _transactionType != TransactionType.income ||
                        !card.isCredit,
                  )
                  .map(
                    (card) => _PayOption(
                      emoji: card.colorEmoji,
                      label: card.name,
                      subtitle: card.isCredit
                          ? '(Crédito)'
                          : card.isDebit
                          ? '(Débito)'
                          : null,
                      onTap: () => _handleSubmit(card.id),
                    ),
                  ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, provider, _) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Balance Section
                _buildBalanceCard(provider),
                const SizedBox(height: 16),

                // Amount & Type Section integrated
                _buildAmountInput(),
                const SizedBox(height: 12),

                // Superemoji Row (horizontal)
                _buildSuperemojiRow(provider),
                const SizedBox(height: 12),

                // Categories with Search
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        // Search Bar inside container
                        _buildSearchBar(),
                        const SizedBox(height: 12),

                        // Scrollable Category Grid
                        Expanded(child: _buildCategoryGrid(provider)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Action Buttons
                _buildActionButtons(provider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBalanceCard(FinanceProvider provider) {
    final creditDebt = provider.totalCreditDebt;
    final debitBalance = provider.totalDebitBalance;
    final hasDebit = provider.cards.any((c) => c.isDebit);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          children: [
            const Text(
              'Balance',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            AnimatedCounter(
              value: provider.balance,
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: provider.balance >= 0
                    ? AppTheme.income
                    : AppTheme.expense,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (provider.cards.any((c) => c.isCredit))
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: creditDebt > 0
                          ? AppTheme.credit.withValues(alpha: 0.2)
                          : AppTheme.income.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      creditDebt > 0
                          ? '💳 -${creditDebt.toStringAsFixed(0)}'
                          : creditDebt < 0
                          ? '💳 +${(-creditDebt).toStringAsFixed(0)}'
                          : '💳 Sin deuda',
                      style: TextStyle(
                        color: creditDebt > 0
                            ? AppTheme.credit
                            : AppTheme.income,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (hasDebit)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: debitBalance >= 0
                          ? AppTheme.income.withValues(alpha: 0.2)
                          : AppTheme.expense.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '🏦 ${debitBalance >= 0 ? '+' : ''}${debitBalance.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: debitBalance >= 0
                            ? AppTheme.income
                            : AppTheme.expense,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAmountInput() {
    final isIncome = _transactionType == TransactionType.income;
    final color = isIncome ? AppTheme.income : AppTheme.expense;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color, width: 2),
              ),
              alignment: Alignment.center,
              child: TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: '\$0',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Stacked Compact Toggles on the right
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CompactTypeButton(
                icon: Icons.remove,
                isSelected: !isIncome,
                color: AppTheme.expense,
                onTap: () =>
                    setState(() => _transactionType = TransactionType.expense),
              ),
              const SizedBox(height: 8),
              _CompactTypeButton(
                icon: Icons.add,
                isSelected: isIncome,
                color: AppTheme.income,
                onTap: () =>
                    setState(() => _transactionType = TransactionType.income),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // _buildTypeToggle removed as it is now integrated/replaced

  Widget _buildSuperemojiRow(FinanceProvider provider) {
    final typeFilter = _transactionType == TransactionType.income
        ? 'income'
        : 'expense';
    final superemojis = provider.categories
        .where(
          (c) =>
              c.isSuperEmoji &&
              c.id != 'credit-payment' &&
              c.type == typeFilter,
        )
        .toList();

    if (superemojis.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: superemojis.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = superemojis[index];
          final isSelected = _selectedCategoryId == category.id;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedCategoryId = category.id);
            },
            child: Tooltip(
              message: category.description,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 56,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.secondary.withValues(alpha: 0.3)
                      : AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppTheme.secondary : Colors.white24,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: AppTheme.secondary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Center(
                  child: Text(
                    category.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryGrid(FinanceProvider provider) {
    final typeFilter = _transactionType == TransactionType.income
        ? 'income'
        : 'expense';
    // Exclude credit-payment, Superemojis, and filter by type
    var categories = provider.categories
        .where(
          (c) =>
              c.id != 'credit-payment' &&
              !c.isSuperEmoji &&
              c.type == typeFilter,
        )
        .toList();

    if (_searchQuery.isNotEmpty) {
      categories = categories
          .where(
            (c) => c.description.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ),
          )
          .toList();
    }

    // Grid with vertical scrolling capability
    return GridView.builder(
      padding: const EdgeInsets.only(top: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5, // Slightly larger items
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final isSelected = _selectedCategoryId == category.id;

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedCategoryId = category.id);
          },
          child: Tooltip(
            message: category.description,
            child: AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primary.withValues(alpha: 0.3)
                      : AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: isSelected
                      ? Border.all(color: AppTheme.primary, width: 2)
                      : null,
                  boxShadow: [
                    if (!isSelected)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 2,
                        offset: const Offset(0, 2),
                      ),
                    if (isSelected)
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Center(
                  child: Text(
                    category.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return SizedBox(
      height: 44, // Taller search bar
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Buscar emoji...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: const Icon(Icons.clear, size: 20),
                )
              : null,
          filled: true,
          fillColor: AppTheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildActionButtons(FinanceProvider provider) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: () => _showPaymentOptions(provider),
        style: ElevatedButton.styleFrom(
          backgroundColor: _transactionType == TransactionType.income
              ? AppTheme.income
              : AppTheme.expense,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          _transactionType == TransactionType.income
              ? 'REGISTRAR INGRESO'
              : 'REGISTRAR GASTO',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _CompactTypeButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _CompactTypeButton({
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isSelected ? color : AppTheme.surfaceVariant,
          shape: BoxShape.circle,
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.grey,
          size: 32,
        ),
      ),
    );
  }
}

class _PayOption extends StatelessWidget {
  final String emoji;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const _PayOption({
    required this.emoji,
    required this.label,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppTheme.surfaceVariant,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Text(emoji, style: const TextStyle(fontSize: 24)),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              )
            : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        dense: true,
      ),
    );
  }
}
