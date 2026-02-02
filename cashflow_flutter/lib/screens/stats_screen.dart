// Stats Screen - Charts and statistics
// Translated from StatsScreen.tsx

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/finance.dart';
import '../providers/finance_provider.dart';
import '../theme/app_theme.dart';

enum Period { week, month, year }

enum ViewType { expenses, income }

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Period _period = Period.month;
  ViewType _viewType = ViewType.expenses;

  final List<Color> _colors = [
    const Color(0xFF8B5CF6),
    const Color(0xFF06B6D4),
    const Color(0xFFF97316),
    const Color(0xFF22C55E),
    const Color(0xFFEF4444),
    const Color(0xFF3B82F6),
    const Color(0xFFEC4899),
    const Color(0xFFEAB308),
  ];

  DateTimeRange _getDateRange() {
    final now = DateTime.now();
    switch (_period) {
      case Period.week:
        final start = now.subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(
          start: DateTime(start.year, start.month, start.day),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case Period.month:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        );
      case Period.year:
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, 12, 31, 23, 59, 59),
        );
    }
  }

  List<Transaction> _filterTransactions(List<Transaction> transactions) {
    final range = _getDateRange();
    return transactions.where((t) {
      final isInRange =
          t.date.isAfter(range.start.subtract(const Duration(seconds: 1))) &&
          t.date.isBefore(range.end.add(const Duration(seconds: 1)));

      if (_viewType == ViewType.expenses) {
        return isInRange &&
            (t.type == TransactionType.expense ||
                t.type == TransactionType.creditExpense);
      } else {
        return isInRange && t.type == TransactionType.income;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, provider, _) {
        final filtered = _filterTransactions(provider.transactions);
        final total = filtered.fold<double>(0, (sum, t) => sum + t.amount);

        // Group by category
        final byCategory = <String, double>{};
        for (final t in filtered) {
          byCategory[t.categoryId] = (byCategory[t.categoryId] ?? 0) + t.amount;
        }

        final sortedCategories = byCategory.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Period selector
                _buildPeriodSelector(),
                const SizedBox(height: 16),

                // View type toggle
                _buildViewTypeToggle(),
                const SizedBox(height: 24),

                // Total
                _buildTotalCard(total),
                const SizedBox(height: 24),

                // Pie Chart
                if (sortedCategories.isNotEmpty) ...[
                  _buildPieChart(sortedCategories, provider, total),
                  const SizedBox(height: 24),

                  // Bar Chart
                  _buildBarChart(sortedCategories, provider),
                  const SizedBox(height: 24),

                  // Category breakdown
                  _buildCategoryList(sortedCategories, provider, total),
                ] else
                  _buildEmptyState(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: Period.values.map((p) {
        final isSelected = p == _period;
        final label = switch (p) {
          Period.week => 'Semana',
          Period.month => 'Mes',
          Period.year => 'Año',
        };
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => setState(() => _period = p),
              selectedColor: AppTheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildViewTypeToggle() {
    return Row(
      children: [
        Expanded(
          child: _ToggleButton(
            label: 'Gastos',
            isSelected: _viewType == ViewType.expenses,
            color: AppTheme.expense,
            onTap: () => setState(() => _viewType = ViewType.expenses),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ToggleButton(
            label: 'Ingresos',
            isSelected: _viewType == ViewType.income,
            color: AppTheme.income,
            onTap: () => setState(() => _viewType = ViewType.income),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalCard(double total) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              _viewType == ViewType.expenses
                  ? 'Total Gastos'
                  : 'Total Ingresos',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              '\$${total.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: _viewType == ViewType.expenses
                    ? AppTheme.expense
                    : AppTheme.income,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(
    List<MapEntry<String, double>> data,
    FinanceProvider provider,
    double total,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: data.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final category = provider.getCategoryById(item.key);
                final percentage = (item.value / total * 100);

                return PieChartSectionData(
                  value: item.value,
                  title: percentage >= 5
                      ? '${percentage.toStringAsFixed(0)}%'
                      : '',
                  color: _colors[index % _colors.length],
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  badgeWidget: percentage >= 10
                      ? Text(
                          category?.emoji ?? '❓',
                          style: const TextStyle(fontSize: 16),
                        )
                      : null,
                  badgePositionPercentageOffset: 1.3,
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(
    List<MapEntry<String, double>> data,
    FinanceProvider provider,
  ) {
    final maxValue = data.isEmpty ? 100.0 : data.first.value;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxValue * 1.2,
              barGroups: data.take(6).toList().asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: item.value,
                      color: _colors[index % _colors.length],
                      width: 24,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, _) {
                      final index = value.toInt();
                      if (index >= 0 && index < data.length) {
                        final category = provider.getCategoryById(
                          data[index].key,
                        );
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            category?.emoji ?? '❓',
                            style: const TextStyle(fontSize: 16),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryList(
    List<MapEntry<String, double>> data,
    FinanceProvider provider,
    double total,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Por categoría',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...data.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final category = provider.getCategoryById(item.key);
          final percentage = (item.value / total * 100);

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _colors[index % _colors.length].withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    category?.emoji ?? '❓',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              title: Text(category?.description ?? 'Desconocido'),
              subtitle: Text('${percentage.toStringAsFixed(1)}%'),
              trailing: Text(
                '\$${item.value.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            const Text('📊', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'Sin datos para este período',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.2)
              : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: color, width: 2) : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? color : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
