// Calculator Screen - Balanced layout, internal scrolling for categories

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/finance.dart';
import '../providers/finance_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/stagger_animation.dart';

final _fmt = NumberFormat('#,##0', 'en_US');

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
              Text(
                _transactionType == TransactionType.income
                    ? 'Registrar Ingreso'
                    : 'Registrar Gasto',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _PayOption(
                emoji: '💵',
                label: 'Efectivo',
                onTap: () => _handleSubmit('cash'),
              ),
              _PayOption(
                emoji: '💳',
                label: 'Tarjeta',
                onTap: () {
                  Navigator.pop(context);
                  _showCardPicker(provider);
                },
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

  void _showCardPicker(FinanceProvider provider) {
    final isIncome = _transactionType == TransactionType.income;

    final entries = <Widget>[];

    for (final card in provider.cards) {
      if (card.isCredit) {
        if (isIncome) continue;
        final debt = provider.getCardDebt(card.id).clamp(0.0, double.infinity);
        final limit = card.creditLimit ?? 0;
        final available = limit - debt;
        if (limit > 0 && available <= 0) continue;
        entries.add(
          ListTile(
            leading: Text(
              card.colorEmoji,
              style: const TextStyle(fontSize: 24),
            ),
            title: Text(
              card.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            trailing: Text(
              '\$${_fmt.format(available)}',
              style: const TextStyle(
                color: AppTheme.credit,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            dense: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            tileColor: AppTheme.surfaceVariant,
            onTap: () => _handleSubmit(card.id),
          ),
        );
        entries.add(const SizedBox(height: 6));
      } else if (card.isDebit) {
        final balance = provider.getDebitBalance(card.id);
        if (!isIncome && balance <= 0) continue;
        entries.add(
          ListTile(
            leading: Text(
              card.colorEmoji,
              style: const TextStyle(fontSize: 24),
            ),
            title: Text(
              card.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            trailing: Text(
              '\$${_fmt.format(balance)}',
              style: const TextStyle(
                color: AppTheme.income,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            dense: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            tileColor: AppTheme.surfaceVariant,
            onTap: () => _handleSubmit(card.id),
          ),
        );
        entries.add(const SizedBox(height: 6));
      }
    }

    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay tarjetas disponibles')),
      );
      return;
    }

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
                'Seleccionar Tarjeta',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...entries,
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
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Balance — just the number + badges, no label
                _buildBalanceCard(provider),
                const SizedBox(height: 12),

                // Amount input — unified colored bar with −/+ at edges
                _buildAmountInput(),
                const SizedBox(height: 12),

                // Superemoji Row (centered)
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
                        _buildSearchBar(),
                        const SizedBox(height: 12),
                        Expanded(child: _buildCategoryGrid(provider)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Action Button
                _buildActionButtons(provider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBalanceCard(FinanceProvider provider) {
    final availableCredit = provider.totalAvailableCredit;
    final debitBalance = provider.totalDebitBalance;

    return Column(
      children: [
        AnimatedCounter(
          value: provider.balance,
          style: TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.bold,
            color: provider.balance >= 0 ? AppTheme.income : AppTheme.expense,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: availableCredit > 0
                    ? AppTheme.credit.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '📙\$${_fmt.format(availableCredit)}',
                style: TextStyle(
                  color: availableCredit > 0 ? AppTheme.credit : Colors.grey,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: debitBalance > 0
                    ? AppTheme.income.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '📗\$${_fmt.format(debitBalance)}',
                style: TextStyle(
                  color: debitBalance > 0 ? AppTheme.income : Colors.grey,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAmountInput() {
    final isIncome = _transactionType == TransactionType.income;
    final color = isIncome ? AppTheme.income : AppTheme.expense;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      height: 72,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 2),
      ),
      child: Row(
        children: [
          // Expense button (left)
          GestureDetector(
            onTap: () =>
                setState(() => _transactionType = TransactionType.expense),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 64,
              height: 72,
              decoration: BoxDecoration(
                color: !isIncome ? AppTheme.expense : Colors.transparent,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(20),
                ),
              ),
              child: Icon(
                Icons.remove,
                color: !isIncome ? Colors.white : Colors.grey[600],
                size: 32,
              ),
            ),
          ),
          // Amount input (center)
          Expanded(
            child: TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '\$0',
                hintStyle: TextStyle(
                  color: color.withValues(alpha: 0.4),
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
            ),
          ),
          // Income button (right)
          GestureDetector(
            onTap: () =>
                setState(() => _transactionType = TransactionType.income),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 64,
              height: 72,
              decoration: BoxDecoration(
                color: isIncome ? AppTheme.income : Colors.transparent,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(20),
                ),
              ),
              child: Icon(
                Icons.add,
                color: isIncome ? Colors.white : Colors.grey[600],
                size: 32,
              ),
            ),
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
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: superemojis.asMap().entries.map((entry) {
              final index = entry.key;
              final category = entry.value;
              final isSelected = _selectedCategoryId == category.id;

              return Padding(
                padding: EdgeInsets.only(left: index == 0 ? 0 : 12),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedCategoryId = category.id);
                  },
                  child: Tooltip(
                    message: category.description,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.secondary.withValues(alpha: 0.3)
                            : AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.secondary
                              : Colors.white24,
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
                ),
              );
            }).toList(),
          ),
        ),
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

class _PayOption extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _PayOption({
    required this.emoji,
    required this.label,
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
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        dense: true,
      ),
    );
  }
}
