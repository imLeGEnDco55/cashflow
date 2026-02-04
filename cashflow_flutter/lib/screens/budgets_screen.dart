import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/finance.dart';
import '../providers/finance_provider.dart';
import '../theme/app_theme.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, provider, _) {
        final categories = provider.categories
            .where((c) => c.id != 'credit-payment')
            .toList();

        // Calculate spending for current month for each category
        final now = DateTime.now();
        final firstDay = DateTime(now.year, now.month, 1);
        final currentMonthTxs = provider.transactions
            .where(
              (t) =>
                  t.date.isAfter(
                    firstDay.subtract(const Duration(seconds: 1)),
                  ) &&
                  (t.type == TransactionType.expense ||
                      t.type == TransactionType.creditExpense),
            )
            .toList();

        final spendingByCat = <String, double>{};
        for (final t in currentMonthTxs) {
          spendingByCat[t.categoryId] =
              (spendingByCat[t.categoryId] ?? 0) + t.amount;
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            final budget = provider.getBudgetForCategory(cat.id);
            final spent = spendingByCat[cat.id] ?? 0.0;

            return _BudgetCard(
              category: cat,
              budget: budget,
              spent: spent,
              onTap: () => _showSetBudgetDialog(context, provider, cat, budget),
            );
          },
        );
      },
    );
  }

  void _showSetBudgetDialog(
    BuildContext context,
    FinanceProvider provider,
    FinanceCategory cat,
    Budget? currentBudget,
  ) {
    final controller = TextEditingController(
      text: currentBudget?.limit.toString() ?? '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Presupuesto: ${cat.emoji} ${cat.description}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Límite mensual',
            prefixText: r'$',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          if (currentBudget != null)
            TextButton(
              onPressed: () {
                provider.setBudget(cat.id, 0);
                Navigator.pop(ctx);
              },
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text) ?? 0;
              provider.setBudget(cat.id, val);
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final FinanceCategory category;
  final Budget? budget;
  final double spent;
  final VoidCallback onTap;

  const _BudgetCard({
    required this.category,
    required this.budget,
    required this.spent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasBudget = budget != null;
    final limit = budget?.limit ?? 0.0;
    final progress = hasBudget ? (spent / limit).clamp(0.0, 1.0) : 0.0;
    final isOver = hasBudget && spent > limit;
    final remaining = hasBudget ? limit - spent : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(category.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.description,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (hasBudget)
                          Text(
                            'Límite: \$${limit.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          )
                        else
                          Text(
                            'Haz tap para establecer presupuesto',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    '\$${spent.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isOver ? AppTheme.expense : Colors.white,
                    ),
                  ),
                ],
              ),
              if (hasBudget) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[800],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isOver
                          ? AppTheme.expense
                          : (progress > 0.8
                                ? AppTheme.credit
                                : AppTheme.income),
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                    Text(
                      isOver
                          ? 'Excedido por \$${(spent - limit).toStringAsFixed(0)}'
                          : 'Restan \$${remaining.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isOver ? AppTheme.expense : AppTheme.income,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
