// Breakdown Editor Modal - Edit Superemoji transaction breakdown
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/finance.dart';
import '../providers/finance_provider.dart';
import '../theme/app_theme.dart';

class BreakdownEditorModal extends StatefulWidget {
  final Transaction transaction;
  final List<FinanceCategory> categories;

  const BreakdownEditorModal({
    super.key,
    required this.transaction,
    required this.categories,
  });

  @override
  State<BreakdownEditorModal> createState() => _BreakdownEditorModalState();
}

class _BreakdownEditorModalState extends State<BreakdownEditorModal> {
  late List<SubEmojiItem> _breakdown;
  final _amountController = TextEditingController();
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _breakdown = List.from(widget.transaction.breakdown ?? []);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double get _assignedTotal =>
      _breakdown.fold(0.0, (sum, item) => sum + item.amount);
  double get _remaining => widget.transaction.amount - _assignedTotal;
  bool get _isBalanced => (_remaining.abs() < 0.01);

  void _addItem() {
    if (_selectedCategoryId == null) return;
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;
    if (_breakdown.length >= 8) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Máximo 8 sub-items')));
      return;
    }

    setState(() {
      _breakdown.add(
        SubEmojiItem(categoryId: _selectedCategoryId!, amount: amount),
      );
      _selectedCategoryId = null;
      _amountController.clear();
    });
  }

  void _removeItem(int index) {
    setState(() => _breakdown.removeAt(index));
  }

  void _save() {
    if (!_isBalanced) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'La suma debe ser exactamente \$${widget.transaction.amount.toStringAsFixed(2)}',
          ),
        ),
      );
      return;
    }
    context.read<FinanceProvider>().updateTransactionBreakdown(
      widget.transaction.id,
      _breakdown,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Filter out Superemojis (only normal categories for breakdown)
    final normalCategories = widget.categories
        .where((c) => !c.isSuperEmoji && c.id != 'credit-payment')
        .toList();

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.pie_chart, color: AppTheme.secondary),
              const SizedBox(width: 12),
              Text(
                'Detallar Gasto',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Total: \$${widget.transaction.amount.toStringAsFixed(2)}',
            style: TextStyle(color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),

          // Progress bar
          LinearProgressIndicator(
            value: (_assignedTotal / widget.transaction.amount).clamp(0.0, 1.0),
            backgroundColor: Colors.grey[800],
            valueColor: AlwaysStoppedAnimation<Color>(
              _isBalanced ? AppTheme.income : AppTheme.secondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isBalanced
                ? '✅ Completado'
                : 'Restante: \$${_remaining.toStringAsFixed(2)}',
            style: TextStyle(
              color: _isBalanced ? AppTheme.income : Colors.grey[400],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),

          // Existing breakdown items
          if (_breakdown.isNotEmpty) ...[
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 150),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _breakdown.length,
                itemBuilder: (context, index) {
                  final item = _breakdown[index];
                  final cat = widget.categories.firstWhere(
                    (c) => c.id == item.categoryId,
                    orElse: () =>
                        FinanceCategory(emoji: '❓', description: 'Desconocido'),
                  );
                  return ListTile(
                    leading: Text(
                      cat.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(cat.description),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('\$${item.amount.toStringAsFixed(2)}'),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.red,
                          ),
                          onPressed: () => _removeItem(index),
                        ),
                      ],
                    ),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  );
                },
              ),
            ),
            const Divider(),
          ],

          // Add new item
          if (_breakdown.length < 8) ...[
            Text(
              'Agregar sub-item:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Category selector
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: normalCategories.length,
                      itemBuilder: (context, index) {
                        final cat = normalCategories[index];
                        final isSelected = _selectedCategoryId == cat.id;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedCategoryId = cat.id),
                          child: Container(
                            width: 40,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primary.withValues(alpha: 0.3)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primary
                                    : Colors.white24,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                cat.emoji,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Amount input
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: '\$',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Add button
                IconButton(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add_circle, color: AppTheme.primary),
                ),
              ],
            ),
          ],

          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isBalanced ? _save : null,
                  child: const Text('Guardar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
