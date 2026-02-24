/// History Screen PRO - Advanced transaction list with filters and grouping
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/finance.dart';
import '../providers/finance_provider.dart';
import '../widgets/transaction_card.dart';
import '../widgets/stagger_animation.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _searchQuery = '';
  String? _selectedCategoryId; // null = all
  String _dateFilter = 'all'; // 'today', 'week', 'month', 'custom', 'all'
  String _typeFilter = 'all'; // 'expense', 'income', 'credit', 'all'
  DateTimeRange? _customDateRange;
  int _displayLimit = 100;

  /// Group transactions by date
  Map<String, List<Transaction>> _groupByDate(List<Transaction> transactions) {
    final grouped = <String, List<Transaction>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final t in transactions) {
      final txDate = DateTime(t.date.year, t.date.month, t.date.day);
      String label;

      if (txDate == today) {
        label = 'Hoy';
      } else if (txDate == yesterday) {
        label = 'Ayer';
      } else if (txDate.year == now.year) {
        label = DateFormat('d MMM', 'es').format(t.date);
      } else {
        label = DateFormat('d MMM yyyy', 'es').format(t.date);
      }

      grouped.putIfAbsent(label, () => []).add(t);
    }
    return grouped;
  }

  /// Apply all filters
  List<Transaction> _filterTransactions(
    List<Transaction> transactions,
    FinanceProvider provider,
  ) {
    var filtered = transactions.toList();

    // Category filter
    if (_selectedCategoryId != null) {
      filtered = filtered
          .where((t) => t.categoryId == _selectedCategoryId)
          .toList();
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((t) {
        final cat = provider.getCategoryById(t.categoryId);
        return cat?.matchesSearch(_searchQuery) ?? false;
      }).toList();
    }

    // Date filter
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_dateFilter) {
      case 'today':
        filtered = filtered.where((t) {
          final txDate = DateTime(t.date.year, t.date.month, t.date.day);
          return txDate == today;
        }).toList();
        break;
      case 'week':
        final weekAgo = today.subtract(const Duration(days: 7));
        filtered = filtered.where((t) => t.date.isAfter(weekAgo)).toList();
        break;
      case 'month':
        final monthAgo = DateTime(now.year, now.month - 1, now.day);
        filtered = filtered.where((t) => t.date.isAfter(monthAgo)).toList();
        break;
      case 'custom':
        if (_customDateRange != null) {
          filtered = filtered.where((t) {
            return t.date.isAfter(_customDateRange!.start) &&
                t.date.isBefore(
                  _customDateRange!.end.add(const Duration(days: 1)),
                );
          }).toList();
        }
        break;
    }

    // Type filter
    switch (_typeFilter) {
      case 'expense':
        filtered = filtered
            .where(
              (t) =>
                  t.type == TransactionType.expense ||
                  t.type == TransactionType.creditExpense,
            )
            .toList();
        break;
      case 'income':
        filtered = filtered
            .where((t) => t.type == TransactionType.income)
            .toList();
        break;
      case 'credit':
        filtered = filtered.where((t) => t.paymentMethod != 'cash').toList();
        break;
    }

    return filtered;
  }

  void _showTransactionEditor(
    FinanceProvider provider,
    Transaction transaction,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) =>
          _TransactionEditorModal(transaction: transaction, provider: provider),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, provider, _) {
        final allTransactions = provider.transactions;

        if (allTransactions.isEmpty) {
          return _buildEmptyState();
        }

        final filtered = _filterTransactions(allTransactions, provider);
        final hasMore = filtered.length > _displayLimit;
        final limited = filtered.take(_displayLimit).toList();

        final grouped = _groupByDate(limited);
        final sortedDates = grouped.keys.toList();

        return Column(
          children: [
            // Search + Filters Header
            _buildHeader(),

            // Transaction List
            Expanded(
              child: filtered.isEmpty
                  ? _buildNoResultsState()
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: sortedDates.length + (hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == sortedDates.length) {
                          return Padding(
                            padding: const EdgeInsets.all(24),
                            child: OutlinedButton(
                              onPressed: () => setState(() {
                                _displayLimit += 100;
                              }),
                              child: const Text('Cargar más'),
                            ),
                          );
                        }
                        final dateLabel = sortedDates[index];
                        final dateTx = grouped[dateLabel]!;
                        final dayTotal = dateTx.fold<double>(
                          0,
                          (sum, t) =>
                              sum +
                              (t.type == TransactionType.income
                                  ? t.amount
                                  : -t.amount),
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date Header
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Row(
                                children: [
                                  Text(
                                    dateLabel,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[400],
                                      fontSize: 13,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${dayTotal >= 0 ? '+' : ''}\$${NumberFormat('#,##0', 'en_US').format(dayTotal)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: dayTotal >= 0
                                          ? AppTheme.income
                                          : AppTheme.expense,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Transactions for this date
                            ...dateTx.asMap().entries.map(
                              (entry) => StaggeredFadeSlide(
                                index: entry.key,
                                child: _buildSwipeableTransaction(
                                  entry.value,
                                  provider,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          // Search bar
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: AppTheme.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                isDense: true,
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          const SizedBox(width: 8),
          // Date filter dropdown
          _buildFilterDropdown(
            icon: Icons.calendar_today,
            value: _dateFilter,
            items: const {
              'all': 'Todo',
              'today': 'Hoy',
              'week': 'Semana',
              'month': 'Mes',
              'custom': '📅 Rango...',
            },
            onChanged: (v) async {
              if (v == 'custom') {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  currentDate: DateTime.now(),
                  initialDateRange: _customDateRange,
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppTheme.primary,
                          onPrimary: Colors.white,
                          surface: AppTheme.surface,
                          onSurface: Colors.white,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (range != null) {
                  setState(() {
                    _customDateRange = range;
                    _dateFilter = 'custom';
                  });
                }
              } else {
                setState(() => _dateFilter = v);
              }
            },
          ),
          const SizedBox(width: 4),
          // Type filter dropdown
          _buildFilterDropdown(
            icon: Icons.filter_list,
            value: _typeFilter,
            items: const {
              'all': 'Todos',
              'expense': '💸 Gastos',
              'income': '💰 Ingresos',
              'credit': '💳 Crédito',
            },
            onChanged: (v) => setState(() => _typeFilter = v),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required IconData icon,
    required String value,
    required Map<String, String> items,
    required Function(String) onChanged,
  }) {
    final isFiltered = value != 'all';
    return PopupMenuButton<String>(
      onSelected: onChanged,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => items.entries
          .map(
            (e) => PopupMenuItem(
              value: e.key,
              child: Row(
                children: [
                  if (value == e.key)
                    const Icon(Icons.check, size: 16, color: AppTheme.primary)
                  else
                    const SizedBox(width: 16),
                  const SizedBox(width: 8),
                  Text(e.value),
                ],
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isFiltered
              ? AppTheme.primary.withValues(alpha: 0.2)
              : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: isFiltered ? Border.all(color: AppTheme.primary) : null,
        ),
        child: Icon(
          icon,
          size: 20,
          color: isFiltered ? AppTheme.primary : Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildSwipeableTransaction(
    Transaction transaction,
    FinanceProvider provider,
  ) {
    final category = provider.getCategoryById(transaction.categoryId);
    final card = transaction.paymentMethod != 'cash'
        ? provider.getCardById(transaction.paymentMethod)
        : null;

    return Dismissible(
      key: Key(transaction.id),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        color: Colors.blue.withValues(alpha: 0.2),
        child: const Row(
          children: [
            Icon(Icons.edit, color: Colors.blue),
            SizedBox(width: 8),
            Text('Editar', style: TextStyle(color: Colors.blue)),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Colors.red.withValues(alpha: 0.2),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Eliminar', style: TextStyle(color: Colors.red)),
            SizedBox(width: 8),
            Icon(Icons.delete, color: Colors.red),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        HapticFeedback.mediumImpact();
        if (direction == DismissDirection.startToEnd) {
          // Swipe right = Edit
          _showTransactionEditor(provider, transaction);
          return false;
        } else {
          // Swipe left = Delete confirmation
          return await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('¿Eliminar transacción?'),
                  content: const Text('Esta acción no se puede deshacer'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Eliminar'),
                    ),
                  ],
                ),
              ) ??
              false;
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          provider.deleteTransaction(transaction.id);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transacción eliminada')),
          );
        }
      },
      child: TransactionCard(
        transaction: transaction,
        category: category,
        card: card,
        categories: provider.categories,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📭', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            'No hay transacciones',
            style: TextStyle(color: Colors.grey[400], fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Registra tu primer gasto o ingreso',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔍', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            'Sin resultados',
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() {
              _searchQuery = '';
              _selectedCategoryId = null;
              _dateFilter = 'all';
              _typeFilter = 'all';
            }),
            child: const Text('Limpiar filtros'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Transaction Editor Modal - Simple amount + breakdown editor
// ============================================================================

class _TransactionEditorModal extends StatefulWidget {
  final Transaction transaction;
  final FinanceProvider provider;

  const _TransactionEditorModal({
    required this.transaction,
    required this.provider,
  });

  @override
  State<_TransactionEditorModal> createState() =>
      _TransactionEditorModalState();
}

class _TransactionEditorModalState extends State<_TransactionEditorModal> {
  late TextEditingController _amountController;
  late List<SubEmojiItem> _breakdown;
  String _breakdownSearch = '';
  final _subAmountController = TextEditingController();
  String? _selectedSubCategoryId;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.transaction.amount.toStringAsFixed(2),
    );
    _breakdown = List.from(widget.transaction.breakdown ?? []);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _subAmountController.dispose();
    super.dispose();
  }

  FinanceCategory? get _currentCategory =>
      widget.provider.getCategoryById(widget.transaction.categoryId);
  bool get _isSuperemoji => _currentCategory?.isSuperEmoji ?? false;
  double get _transactionAmount =>
      double.tryParse(_amountController.text) ?? widget.transaction.amount;
  double get _assignedTotal =>
      _breakdown.fold(0.0, (sum, item) => sum + item.amount);
  double get _remaining => _transactionAmount - _assignedTotal;
  bool get _isBalanced => _remaining.abs() < 0.01;

  void _addBreakdownItem() {
    if (_selectedSubCategoryId == null) return;
    final amount = double.tryParse(_subAmountController.text) ?? 0;
    if (amount <= 0) return;
    if (_breakdown.length >= 8) return;

    setState(() {
      _breakdown.add(
        SubEmojiItem(categoryId: _selectedSubCategoryId!, amount: amount),
      );
      _selectedSubCategoryId = null;
      _subAmountController.clear();
    });
  }

  void _save() {
    final newAmount = double.tryParse(_amountController.text);
    if (newAmount != null && newAmount != widget.transaction.amount) {
      widget.provider.updateTransactionAmount(widget.transaction.id, newAmount);
    }

    if (_isSuperemoji) {
      widget.provider.updateTransactionBreakdown(
        widget.transaction.id,
        _breakdown,
      );
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Transacción actualizada')));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Text(
                _currentCategory?.emoji ?? '📦',
                style: const TextStyle(fontSize: 40),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentCategory?.description ?? 'Transacción',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat(
                        'd MMM yyyy, HH:mm',
                        'es',
                      ).format(widget.transaction.date),
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Amount Editor
          Row(
            children: [
              const Text(
                '\$',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),

          // Recurring toggle
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              widget.provider.toggleTransactionRecurring(widget.transaction.id);
              setState(() {});
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.transaction.isRecurring
                    ? AppTheme.income.withValues(alpha: 0.2)
                    : AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: widget.transaction.isRecurring
                    ? Border.all(color: AppTheme.income)
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.repeat,
                    size: 20,
                    color: widget.transaction.isRecurring
                        ? AppTheme.income
                        : Colors.grey[400],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transacción Fija',
                          style: TextStyle(
                            fontWeight: widget.transaction.isRecurring
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: widget.transaction.isRecurring
                                ? Colors.white
                                : Colors.grey[400],
                          ),
                        ),
                        Text(
                          'Ej: sueldo, renta, servicios',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    widget.transaction.isRecurring
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    color: widget.transaction.isRecurring
                        ? AppTheme.income
                        : Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),

          // Breakdown section (only for Superemojis)
          if (_isSuperemoji) ...[
            const SizedBox(height: 20),
            _buildBreakdownSection(),
          ],

          const SizedBox(height: 20),

          // Save button
          ElevatedButton(
            onPressed: (_isSuperemoji && !_isBalanced) ? null : _save,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              _isSuperemoji && !_isBalanced
                  ? 'Resta \$${_remaining.toStringAsFixed(2)}'
                  : 'Guardar',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownSection() {
    // Filter categories by search
    var normalCategories = widget.provider.categories
        .where((c) => !c.isSuperEmoji && c.id != 'credit-payment')
        .toList();

    if (_breakdownSearch.isNotEmpty) {
      normalCategories = normalCategories
          .where(
            (c) => c.description.toLowerCase().contains(
              _breakdownSearch.toLowerCase(),
            ),
          )
          .toList();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.pie_chart, size: 16, color: AppTheme.secondary),
              const SizedBox(width: 8),
              const Text(
                'Desglose',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                _isBalanced ? '✅' : 'Resta: \$${_remaining.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 12,
                  color: _isBalanced ? AppTheme.income : AppTheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Existing breakdown items
          ...(_breakdown.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final cat = widget.provider.getCategoryById(item.categoryId);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text(cat?.emoji ?? '❓', style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(cat?.description ?? 'Desconocido')),
                  Text('\$${item.amount.toStringAsFixed(2)}'),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.red),
                    onPressed: () => setState(() => _breakdown.removeAt(idx)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            );
          })),

          // Add new item
          if (_breakdown.length < 8) ...[
            const SizedBox(height: 8),
            // Search bar for categories
            TextField(
              decoration: InputDecoration(
                hintText: 'Buscar categoría...',
                prefixIcon: const Icon(Icons.search, size: 18),
                filled: true,
                fillColor: AppTheme.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              onChanged: (v) => setState(() => _breakdownSearch = v),
            ),
            const SizedBox(height: 8),
            // Category selector + amount
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: normalCategories.length,
                      itemBuilder: (context, idx) {
                        final cat = normalCategories[idx];
                        final isSelected = _selectedSubCategoryId == cat.id;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedSubCategoryId = cat.id),
                          child: Container(
                            width: 40,
                            margin: const EdgeInsets.only(right: 6),
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
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 70,
                  child: TextField(
                    controller: _subAmountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: '\$',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _addBreakdownItem,
                  icon: const Icon(
                    Icons.add_circle,
                    color: AppTheme.primary,
                    size: 28,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// EOF
