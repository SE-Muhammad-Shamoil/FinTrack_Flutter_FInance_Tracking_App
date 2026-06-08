import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:finguard_ai/presentation/providers/app_providers.dart';
import 'package:finguard_ai/core/theme/app_theme.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(monthlyBudgetProgressProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
      ),
      body: budgetsAsync.when(
        data: (budgets) {
          if (budgets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pie_chart_outline_rounded, size: 80, color: Colors.grey.withAlpha(76)),
                  const SizedBox(height: 16),
                  const Text('No budgets set for this month.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => const _AddBudgetModal(),
                      );
                    },
                    child: const Text('Create Budget'),
                  )
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildChartSection(budgets, theme, isDark),
                const SizedBox(height: 40),
                Text('Category Breakdown', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildBudgetsList(budgets, theme, isDark),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: isDark ? AppTheme.neumorphicShadowDark : AppTheme.neumorphicShadowLight,
        ),
        child: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (ctx) => const _AddBudgetModal(),
            );
          },
          child: const Icon(Icons.add_rounded, size: 32),
        ),
      ),
    );
  }

  Widget _buildChartSection(List<Map<String, dynamic>> budgets, ThemeData theme, bool isDark) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark ? AppTheme.neumorphicShadowDark : AppTheme.neumorphicShadowLight,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 80,
              sections: budgets.map((b) {
                final color = Color(int.parse(b['color'].replaceFirst('#', '0xFF')));
                return PieChartSectionData(
                  color: color,
                  value: b['budget'] > 0 ? b['budget'] : 1,
                  title: '',
                  radius: 24,
                  badgeWidget: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.surfaceDark : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withAlpha(51), blurRadius: 4, offset: const Offset(0, 2))
                      ],
                    ),
                    child: Icon(Icons.category, size: 16, color: color), // Placeholder for icon parsing
                  ),
                  badgePositionPercentageOffset: 1.2,
                );
              }).toList(),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total Budget', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 14)),
              const SizedBox(height: 4),
              Text(
                'Rs. ${budgets.fold<double>(0.0, (sum, item) => sum + item['budget']).toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBudgetsList(List<Map<String, dynamic>> budgets, ThemeData theme, bool isDark) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: budgets.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final b = budgets[index];
        final color = Color(int.parse(b['color'].replaceFirst('#', '0xFF')));
        final isOver = b['isOver'];
        final percent = b['percentage'];

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isDark ? AppTheme.neumorphicShadowDark : AppTheme.neumorphicShadowLight,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: color.withAlpha(25), shape: BoxShape.circle),
                    child: Icon(Icons.category, color: color),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b['category_name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(isOver ? 'Over budget!' : 'On track', 
                          style: TextStyle(color: isOver ? Colors.redAccent : Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Rs. ${b['spent'].toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('of Rs. ${b['budget'].toStringAsFixed(0)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percent,
                  backgroundColor: color.withAlpha(25),
                  valueColor: AlwaysStoppedAnimation<Color>(isOver ? Colors.redAccent : color),
                  minHeight: 8,
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

class _AddBudgetModal extends ConsumerStatefulWidget {
  const _AddBudgetModal();

  @override
  ConsumerState<_AddBudgetModal> createState() => _AddBudgetModalState();
}

class _AddBudgetModalState extends ConsumerState<_AddBudgetModal> {
  final _amountController = TextEditingController();
  int? _selectedCategoryId;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0 || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields validly')));
      return;
    }

    final db = await ref.read(databaseHelperProvider).database;
    final profileId = ref.read(activeProfileIdProvider);
    final now = DateTime.now();

    // Check if budget for this category already exists for this month
    final existing = await db.query(
      'budgets',
      where: 'profile_id = ? AND category_id = ? AND month = ? AND year = ?',
      whereArgs: [profileId, _selectedCategoryId, now.month, now.year]
    );

    if (existing.isNotEmpty) {
      // Update
      await db.update(
        'budgets',
        {'amount': amount},
        where: 'id = ?',
        whereArgs: [existing.first['id']]
      );
    } else {
      // Insert
      await db.insert('budgets', {
        'profile_id': profileId,
        'category_id': _selectedCategoryId,
        'amount': amount,
        'month': now.month,
        'year': now.year,
      });
    }

    ref.invalidate(monthlyBudgetProgressProvider);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _createNewCategory() async {
    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Category'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: 'Category Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, nameController.text.trim()), child: const Text('Create')),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final db = await ref.read(databaseHelperProvider).database;
      final profileId = ref.read(activeProfileIdProvider);
      final id = await db.insert('categories', {
        'profile_id': profileId,
        'name': result,
        'icon': 'category',
        'color': '#607D8B',
        'type': 'expense',
        'keyword_mappings': '[]',
      });
      ref.invalidate(categoriesProvider);
      setState(() {
        _selectedCategoryId = id;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categoriesAsync = ref.watch(categoriesProvider);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Set Budget', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Budget Amount (Rs)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          categoriesAsync.when(
            data: (categories) {
              final expenseCategories = categories.where((c) => c['type'] == 'expense').toList();
              bool selectedIsValid = _selectedCategoryId == null || expenseCategories.any((c) => c['id'] == _selectedCategoryId);

              return DropdownButtonFormField<int>(
                value: selectedIsValid ? _selectedCategoryId : null,
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                items: [
                  ...expenseCategories.map((c) {
                    return DropdownMenuItem<int>(
                      value: c['id'] as int,
                      child: Text(c['name'] as String),
                    );
                  }),
                  const DropdownMenuItem<int>(
                    value: -1,
                    child: Text('Create New...', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  ),
                ],
                onChanged: (val) {
                  if (val == -1) {
                    _createNewCategory();
                  } else {
                    setState(() => _selectedCategoryId = val);
                  }
                },
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Save Budget', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
