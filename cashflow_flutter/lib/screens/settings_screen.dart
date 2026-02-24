// Settings Screen - Categories, cards, and data management
// Translated from SettingsScreen.tsx

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/finance.dart';
import '../providers/finance_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _handleExport() async {
    final provider = context.read<FinanceProvider>();
    final data = provider.exportData();

    try {
      // Get download directory
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/cashflow_backup_$timestamp.json');
      await file.writeAsString(data);

      // Let user pick where to save
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar backup',
        fileName: 'cashflow_backup_$timestamp.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: utf8.encode(data),
      );

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Exportado a: ${result.split('/').last}'),
            backgroundColor: AppTheme.income,
          ),
        );
      }
    } catch (e) {
      // Fallback to clipboard
      await Clipboard.setData(ClipboardData(text: data));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '📋 Copiado al portapapeles (no se pudo guardar archivo)',
            ),
            backgroundColor: AppTheme.credit,
          ),
        );
      }
    }
  }

  void _handleImport() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        if (!mounted) return;
        final data = utf8.decode(result.files.single.bytes!);
        final provider = context.read<FinanceProvider>();
        final success = provider.importData(data);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? '✅ Datos importados correctamente'
                    : '❌ Error al importar',
              ),
              backgroundColor: success ? AppTheme.income : AppTheme.expense,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: AppTheme.expense,
          ),
        );
      }
    }
  }

  void _handleCSVExport() async {
    final provider = context.read<FinanceProvider>();
    try {
      await provider.exportToCSV();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ CSV exportado y compartido'),
            backgroundColor: AppTheme.income,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al exportar: $e'),
            backgroundColor: AppTheme.expense,
          ),
        );
      }
    }
  }

  void _confirmDeleteCategory(FinanceCategory category) async {
    final provider = context.read<FinanceProvider>();
    if (!provider.canDeleteCategory(category.id)) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('⚠️ Categoría en uso'),
          content: Text(
            'La categoría "${category.description}" tiene transacciones asociadas. ¿Estás seguro de que quieres eliminarla?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }
    provider.deleteCategory(category.id);
  }

  void _confirmDeleteCard(FinanceCard card) async {
    final provider = context.read<FinanceProvider>();
    if (!provider.canDeleteCard(card.id)) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('⚠️ Tarjeta en uso'),
          content: Text(
            'La tarjeta "${card.name}" tiene transacciones asociadas. ¿Estás seguro de que quieres eliminarla?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }
    provider.deleteCard(card.id);
  }

  void _showCategoryEditor({FinanceCategory? category}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CategoryEditor(
        category: category,
        onSave: (emoji, description, isSuperEmoji, aliases, type) {
          final provider = context.read<FinanceProvider>();
          try {
            if (category != null) {
              provider.updateCategory(
                category.id,
                emoji: emoji,
                description: description,
                isSuperEmoji: isSuperEmoji,
                aliases: aliases,
                type: type,
              );
            } else {
              provider.addCategory(
                emoji: emoji,
                description: description,
                isSuperEmoji: isSuperEmoji,
                aliases: aliases,
                type: type,
              );
            }
            Navigator.pop(context);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '❌ ${e.toString().replaceAll("Exception: ", "")}',
                ),
                backgroundColor: AppTheme.expense,
              ),
            );
          }
        },
      ),
    );
  }

  void _showCardEditor({FinanceCard? card}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CardEditor(
        card: card,
        onSave: (name, type, colorEmoji, cutOffDay, paymentDay, creditLimit) {
          final provider = context.read<FinanceProvider>();
          try {
            if (card != null) {
              provider.updateCard(
                card.id,
                name: name,
                type: type,
                colorEmoji: colorEmoji,
                cutOffDay: cutOffDay,
                paymentDay: paymentDay,
                creditLimit: creditLimit,
              );
            } else {
              provider.addCard(
                name: name,
                type: type,
                colorEmoji: colorEmoji,
                cutOffDay: cutOffDay,
                paymentDay: paymentDay,
                creditLimit: creditLimit,
              );
            }
            Navigator.pop(context);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '❌ ${e.toString().replaceAll("Exception: ", "")}',
                ),
                backgroundColor: AppTheme.expense,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, provider, _) {
        return SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Categories ExpansionTile
                _buildCategoriesSection(provider),
                const SizedBox(height: 16),

                // Cards ExpansionTile
                _buildCardsSection(provider),
                const SizedBox(height: 16),

                // Data management
                _buildDataSection(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoriesSection(FinanceProvider provider) {
    final categories = provider.categories
        .where((c) => c.id != 'credit-payment')
        .toList();
    final superemojis = categories.where((c) => c.isSuperEmoji).toList();
    final normalCategories = categories.where((c) => !c.isSuperEmoji).toList();

    return Card(
      child: ListTile(
        leading: const Icon(Icons.category, color: AppTheme.primary),
        title: const Text(
          'Categorías',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${superemojis.length} ⚡ • ${normalCategories.length} normales',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showCategoriesModal(provider),
      ),
    );
  }

  void _showCategoriesModal(FinanceProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          final cats = provider.categories
              .where((c) => c.id != 'credit-payment')
              .toList();
          final supers = cats.where((c) => c.isSuperEmoji).toList();
          final expenses = cats
              .where((c) => !c.isSuperEmoji && c.isExpense)
              .toList();
          final incomes = cats
              .where((c) => !c.isSuperEmoji && c.isIncome)
              .toList();

          return Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Categorías',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showCategoryEditor();
                      },
                      icon: const Icon(
                        Icons.add_circle,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Superemojis Section
                    if (supers.isNotEmpty) ...[
                      const Row(
                        children: [
                          Icon(Icons.star, size: 16, color: AppTheme.secondary),
                          SizedBox(width: 8),
                          Text(
                            'Superemojis',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...supers.map((c) => _buildCategoryTile(c, provider)),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                    ],
                    // Expense Categories Section
                    const Row(
                      children: [
                        Text('💸 ', style: TextStyle(fontSize: 14)),
                        Text(
                          'Gastos',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.expense,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...expenses.map((c) => _buildCategoryTile(c, provider)),
                    if (incomes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      // Income Categories Section
                      const Row(
                        children: [
                          Text('💰 ', style: TextStyle(fontSize: 14)),
                          Text(
                            'Ingresos',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.income,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...incomes.map((c) => _buildCategoryTile(c, provider)),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryTile(
    FinanceCategory category,
    FinanceProvider provider,
  ) {
    final isDefault =
        int.tryParse(category.id) != null && int.parse(category.id) <= 8;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Stack(
        children: [
          Text(category.emoji, style: const TextStyle(fontSize: 28)),
          if (category.isSuperEmoji)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppTheme.secondary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star, size: 10, color: Colors.white),
              ),
            ),
        ],
      ),
      title: Text(category.description),
      subtitle: category.isSuperEmoji
          ? const Text(
              '⚡ Superemoji',
              style: TextStyle(fontSize: 11, color: AppTheme.secondary),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () {
              Navigator.pop(context);
              _showCategoryEditor(category: category);
            },
          ),
          if (!isDefault)
            IconButton(
              icon: Icon(Icons.delete, size: 20, color: Colors.red[300]),
              onPressed: () => _confirmDeleteCategory(category),
            ),
        ],
      ),
    );
  }

  Widget _buildCardsSection(FinanceProvider provider) {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.credit_card, color: AppTheme.secondary),
        title: const Text(
          'Tarjetas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${provider.cards.length} tarjetas'),
        children: [
          if (provider.cards.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Text('💳', style: TextStyle(fontSize: 32)),
                  SizedBox(height: 8),
                  Text('No hay tarjetas', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.cards.length,
              itemBuilder: (context, index) {
                final card = provider.cards[index];
                final debt = provider.getCardDebt(card.id);

                return ListTile(
                  leading: Text(
                    card.colorEmoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                  title: Text(card.name),
                  subtitle: Text(
                    card.isCredit
                        ? 'Crédito${debt > 0 ? ' • Deuda: \$${debt.toStringAsFixed(2)}' : ''}'
                        : 'Débito',
                    style: TextStyle(
                      color: card.isCredit && debt > 0
                          ? AppTheme.credit
                          : Colors.grey,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _showCardEditor(card: card),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete,
                          size: 20,
                          color: Colors.red[300],
                        ),
                        onPressed: () => _confirmDeleteCard(card),
                      ),
                    ],
                  ),
                );
              },
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () => _showCardEditor(),
              icon: const Icon(Icons.add),
              label: const Text('Nueva Tarjeta'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataSection() {
    return Card(
      child: Column(
        children: [
          Consumer<FinanceProvider>(
            builder: (context, provider, child) {
              return SwitchListTile(
                secondary: const Icon(
                  Icons.notifications_active,
                  color: AppTheme.primary,
                ),
                title: const Text('Recordatorios de pago'),
                subtitle: const Text('Notificar fechas de corte/pago'),
                value: provider.remindersEnabled,
                onChanged: (v) => provider.toggleReminders(v),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.upload_file, color: AppTheme.primary),
            title: const Text('Exportar datos'),
            subtitle: const Text('Guardar backup en archivo JSON'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _handleExport,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.table_chart, color: Colors.green),
            title: const Text('Exportar CSV'),
            subtitle: const Text('Para Excel/Sheets'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _handleCSVExport,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.download, color: AppTheme.secondary),
            title: const Text('Importar datos'),
            subtitle: const Text('Restaurar desde archivo JSON'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _handleImport,
          ),
        ],
      ),
    );
  }
}

// Category Editor Bottom Sheet
class _CategoryEditor extends StatefulWidget {
  final FinanceCategory? category;
  final Function(
    String emoji,
    String description,
    bool isSuperEmoji,
    String? aliases,
    String type,
  )
  onSave;

  const _CategoryEditor({this.category, required this.onSave});

  @override
  State<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends State<_CategoryEditor> {
  late String _emoji;
  late TextEditingController _descController;
  late TextEditingController _aliasesController;
  late bool _isSuperEmoji;
  late String _type;

  @override
  void initState() {
    super.initState();
    _emoji = widget.category?.emoji ?? '📦';
    _descController = TextEditingController(
      text: widget.category?.description ?? '',
    );
    _aliasesController = TextEditingController(
      text: widget.category?.aliases ?? '',
    );
    _isSuperEmoji = widget.category?.isSuperEmoji ?? false;
    _type = widget.category?.type ?? 'expense';
  }

  @override
  void dispose() {
    _descController.dispose();
    _aliasesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
          Text(
            widget.category != null ? 'Editar Categoría' : 'Nueva Categoría',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emoji Input
              Container(
                width: 80,
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: _isSuperEmoji
                            ? AppTheme.secondary.withValues(alpha: 0.2)
                            : AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isSuperEmoji
                              ? AppTheme.secondary
                              : AppTheme.primary,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _emoji,
                          style: const TextStyle(fontSize: 40),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: 'Emoji',
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          // Take first grapheme cluster (emoji-safe)
                          final chars = value.characters;
                          setState(() => _emoji = chars.first);
                        }
                      },
                    ),
                  ],
                ),
              ),

              // Description + Aliases Input
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    TextField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la categoría',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _aliasesController,
                      decoration: InputDecoration(
                        labelText: 'Aliases (opcional)',
                        hintText: 'Ej: mandado, super, compras',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                        border: const OutlineInputBorder(),
                        helperText: 'Separa con comas para búsqueda',
                        helperStyle: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                        ),
                      ),
                      textCapitalization: TextCapitalization.none,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Superemoji Toggle
          GestureDetector(
            onTap: () => setState(() => _isSuperEmoji = !_isSuperEmoji),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _isSuperEmoji
                    ? AppTheme.secondary.withValues(alpha: 0.2)
                    : AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: _isSuperEmoji
                    ? Border.all(color: AppTheme.secondary, width: 2)
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    _isSuperEmoji ? Icons.star : Icons.star_border,
                    color: _isSuperEmoji ? AppTheme.secondary : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Superemoji',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _isSuperEmoji
                                ? AppTheme.secondary
                                : Colors.white,
                          ),
                        ),
                        Text(
                          'Permite detallar sub-gastos después',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isSuperEmoji,
                    onChanged: (v) => setState(() => _isSuperEmoji = v),
                    activeThumbColor: AppTheme.secondary,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Type Toggle: Gasto / Ingreso
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    _type == 'income' ? Icons.trending_up : Icons.trending_down,
                    color: _type == 'income'
                        ? AppTheme.income
                        : AppTheme.expense,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _type == 'income' ? 'Ingreso' : 'Gasto',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _type == 'income'
                                ? AppTheme.income
                                : AppTheme.expense,
                          ),
                        ),
                        Text(
                          _type == 'income'
                              ? 'Aparece solo en modo +'
                              : 'Aparece solo en modo -',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _type == 'income',
                    onChanged: (v) =>
                        setState(() => _type = v ? 'income' : 'expense'),
                    activeThumbColor: AppTheme.income,
                    inactiveThumbColor: AppTheme.expense,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

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
                  onPressed: () {
                    if (_descController.text.trim().isNotEmpty) {
                      final aliases = _aliasesController.text.trim().isEmpty
                          ? null
                          : _aliasesController.text.trim();
                      widget.onSave(
                        _emoji,
                        _descController.text.trim(),
                        _isSuperEmoji,
                        aliases,
                        _type,
                      );
                    }
                  },
                  child: Text(widget.category != null ? 'Guardar' : 'Agregar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Card Editor Bottom Sheet
class _CardEditor extends StatefulWidget {
  final FinanceCard? card;
  final Function(
    String name,
    String type,
    String colorEmoji,
    int? cutOffDay,
    int? paymentDay,
    double? creditLimit,
  )
  onSave;

  const _CardEditor({this.card, required this.onSave});

  @override
  State<_CardEditor> createState() => _CardEditorState();
}

class _CardEditorState extends State<_CardEditor> {
  late String _colorEmoji;
  late String _type;
  late TextEditingController _nameController;
  late TextEditingController _cutOffController;
  late TextEditingController _paymentController;
  late TextEditingController _creditLimitController;

  @override
  void initState() {
    super.initState();
    _colorEmoji = widget.card?.colorEmoji ?? '🟦';
    _type = widget.card?.type ?? 'debit';
    _nameController = TextEditingController(text: widget.card?.name ?? '');
    _cutOffController = TextEditingController(
      text: widget.card?.cutOffDay?.toString() ?? '',
    );
    _paymentController = TextEditingController(
      text: widget.card?.paymentDay?.toString() ?? '',
    );
    _creditLimitController = TextEditingController(
      text: widget.card?.creditLimit?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cutOffController.dispose();
    _paymentController.dispose();
    _creditLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
          Text(
            widget.card != null ? 'Editar Tarjeta' : 'Nueva Tarjeta',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Color grid
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: cardColors
                .map(
                  (color) => GestureDetector(
                    onTap: () => setState(() => _colorEmoji = color),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _colorEmoji == color
                            ? AppTheme.primary.withValues(alpha: 0.3)
                            : AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                        border: _colorEmoji == color
                            ? Border.all(color: AppTheme.primary, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          color,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _nameController,
            decoration: const InputDecoration(hintText: 'Nombre de la tarjeta'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),

          // Type selector
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _type = 'debit'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _type == 'debit'
                          ? AppTheme.primary.withValues(alpha: 0.2)
                          : AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: _type == 'debit'
                          ? Border.all(color: AppTheme.primary, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        'Débito',
                        style: TextStyle(
                          color: _type == 'debit'
                              ? AppTheme.primary
                              : Colors.grey,
                          fontWeight: _type == 'debit'
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _type = 'credit'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _type == 'credit'
                          ? AppTheme.credit.withValues(alpha: 0.2)
                          : AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: _type == 'credit'
                          ? Border.all(color: AppTheme.credit, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        'Crédito',
                        style: TextStyle(
                          color: _type == 'credit'
                              ? AppTheme.credit
                              : Colors.grey,
                          fontWeight: _type == 'credit'
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Credit card specific fields
          if (_type == 'credit') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cutOffController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Día corte',
                      isDense: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _paymentController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Día pago',
                      isDense: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _creditLimitController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                hintText: 'Límite de crédito (opcional)',
                prefixText: '\$ ',
                isDense: true,
              ),
            ),
          ],
          const SizedBox(height: 24),

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
                  onPressed: () {
                    if (_nameController.text.trim().isNotEmpty) {
                      widget.onSave(
                        _nameController.text.trim(),
                        _type,
                        _colorEmoji,
                        int.tryParse(_cutOffController.text),
                        int.tryParse(_paymentController.text),
                        double.tryParse(_creditLimitController.text),
                      );
                    }
                  },
                  child: Text(widget.card != null ? 'Guardar' : 'Agregar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
