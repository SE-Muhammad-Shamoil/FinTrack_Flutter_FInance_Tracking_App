import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finguard_ai/core/theme/app_theme.dart';
import 'package:finguard_ai/presentation/providers/app_providers.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:finguard_ai/domain/entities/profile.dart';
import 'package:finguard_ai/domain/entities/transaction.dart' as entity;

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final budgetsAsync = ref.watch(monthlyBudgetProgressProvider);
    final totalIncomeAsync = ref.watch(totalIncomeProvider);
    final totalIncome = totalIncomeAsync.value ?? 0.0;
    final totalSpendingAsync = ref.watch(totalSpendingProvider);
    final trueTotalSpent = totalSpendingAsync.value ?? 0.0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: budgetsAsync.when(
          data: (budgets) {
            double totalBudget = 0;
            for (var b in budgets) {
              totalBudget += b['budget'] as double;
            }
            double leftBudget = totalBudget - trueTotalSpent;
            if (leftBudget < 0) leftBudget = 0;

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24).copyWith(bottom: 120),
              children: [
                _buildHeader(context, theme, isDark, ref),
                const SizedBox(height: 32),
                _buildTotalBalanceCard(theme, isDark, trueTotalSpent, totalIncome, leftBudget, totalBudget, ref),
                const SizedBox(height: 32),
                _buildOverviewHeader(theme),
                const SizedBox(height: 24),
                _buildSpendingChart(theme, isDark, ref),
                const SizedBox(height: 32),
                _buildBudgetsList(theme, isDark, budgets, ref),
                const SizedBox(height: 32),
                _buildRecentTransactions(context, ref, theme, isDark),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, bool isDark, WidgetRef ref) {
    final profilesAsync = ref.watch(profilesProvider);
    final activeId = ref.watch(activeProfileIdProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        profilesAsync.when(
          data: (profiles) {
            final activeProfile = profiles.firstWhere((p) => p.id == activeId, orElse: () => profiles.first);
            return GestureDetector(
              onTap: () => _showProfileOverlay(context, ref, profiles),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(int.parse(activeProfile.color.replaceFirst('#', '0xFF'))).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.person_rounded, color: Color(int.parse(activeProfile.color.replaceFirst('#', '0xFF')))),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            activeProfile.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                        ],
                      ),
                      Text(
                        'Welcome back!',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
          loading: () => const SizedBox(width: 150, height: 48, child: Center(child: CircularProgressIndicator())),
          error: (_, __) => const SizedBox.shrink(),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            shape: BoxShape.circle,
            boxShadow: isDark ? AppTheme.neumorphicShadowDark : AppTheme.neumorphicShadowLight,
          ),
          child: Icon(Icons.notifications_none_rounded, color: theme.primaryColor, size: 20),
        ),
      ],
    );
  }

  Widget _buildTotalBalanceCard(ThemeData theme, bool isDark, double totalSpent, double totalIncome, double leftBudget, double totalBudget, WidgetRef ref) {
    final currencySymbol = ref.watch(currencySymbolProvider);
    final currency = NumberFormat.currency(symbol: currencySymbol);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: isDark ? AppTheme.neumorphicShadowDark : AppTheme.neumorphicShadowLight,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spent',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                currency.format(totalSpent),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Income',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                currency.format(totalIncome),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isDark ? AppTheme.neumorphicShadowDark : AppTheme.neumorphicShadowLight,
                  ),
                  child: Column(
                    children: [
                      Text('Budget Left', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade500)),
                      const SizedBox(height: 4),
                      Text(currency.format(leftBudget), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isDark ? AppTheme.neumorphicShadowDark : AppTheme.neumorphicShadowLight,
                  ),
                  child: Column(
                    children: [
                      Text('Total Budget', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade500)),
                      const SizedBox(height: 4),
                      Text(currency.format(totalBudget), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildOverviewHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending Overview',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'By categories this month',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpendingChart(ThemeData theme, bool isDark, WidgetRef ref) {
    final catSpendingAsync = ref.watch(categorySpendingProvider);

    return catSpendingAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return Container(
            height: 200,
            alignment: Alignment.center,
            child: const Text('No spending data yet!', style: TextStyle(color: Colors.grey)),
          );
        }

        double totalSpent = 0;
        for (var c in categories) {
          totalSpent += c['spent'] as double;
        }

        final currencySymbol = ref.watch(currencySymbolProvider);
        final currency = NumberFormat.currency(symbol: currencySymbol);

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: isDark ? AppTheme.neumorphicShadowDark : AppTheme.neumorphicShadowLight,
          ),
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 60,
                        sections: categories.map((c) {
                          final color = Color(int.parse(c['color'].replaceFirst('#', '0xFF')));
                          final spent = c['spent'] as double;
                          final percentage = totalSpent > 0 ? (spent / totalSpent * 100).toStringAsFixed(1) : '0.0';
                          return PieChartSectionData(
                            color: color,
                            value: spent,
                            title: '',
                            radius: 20,
                            badgeWidget: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
                                ],
                              ),
                              child: Text(
                                '$percentage%',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                            badgePositionPercentageOffset: 1.3,
                          );
                        }).toList(),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Categories', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          '${categories.length}',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: categories.map((c) {
                  final color = Color(int.parse(c['color'].replaceFirst('#', '0xFF')));
                  final spent = c['spent'] as double;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${c['category_name']} • ${currency.format(spent)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 250, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => SizedBox(height: 250, child: Center(child: Text('Error: $e'))),
    );
  }

  Widget _buildBudgetsList(ThemeData theme, bool isDark, List<Map<String, dynamic>> budgets, WidgetRef ref) {
    if (budgets.isEmpty) return const SizedBox.shrink();

    final currencySymbol = ref.watch(currencySymbolProvider);
    final currency = NumberFormat.currency(symbol: currencySymbol);

    double totalBudget = 0;
    for (var b in budgets) {
      totalBudget += b['budget'] as double;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: isDark ? AppTheme.neumorphicShadowDark : AppTheme.neumorphicShadowLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Budget Allocation',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 60,
                    sections: budgets.map((b) {
                      final color = Color(int.parse(b['color'].replaceFirst('#', '0xFF')));
                      final budgetAmt = b['budget'] as double;
                      return PieChartSectionData(
                        color: color,
                        value: budgetAmt,
                        title: '',
                        radius: 20,
                        badgeWidget: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
                            ],
                          ),
                          child: Icon(
                            Icons.category,
                            size: 16,
                            color: color,
                          ),
                        ),
                        badgePositionPercentageOffset: 1.2,
                      );
                    }).toList(),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Total Budget', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      currency.format(totalBudget),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 32),
          ...budgets.map((b) {
            final color = Color(int.parse(b['color'].replaceFirst('#', '0xFF')));
            final spent = b['spent'] as double;
            final budgetAmt = b['budget'] as double;
            final percentage = b['percentage'] as double;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.category, color: color, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b['category_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Spent: ${currency.format(spent)}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                            Text('Limit: ${currency.format(budgetAmt)}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 6,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: percentage,
                            child: Container(
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showProfileOverlay(BuildContext context, WidgetRef ref, List<Profile> profiles) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Select Profile', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...profiles.map((p) {
                final isActive = ref.read(activeProfileIdProvider) == p.id;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isActive ? theme.primaryColor.withValues(alpha: 0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: isActive ? Border.all(color: theme.primaryColor.withValues(alpha: 0.5)) : null,
                  ),
                  child: ListTile(
                    leading: Icon(Icons.person_rounded, color: Color(int.parse(p.color.replaceFirst('#', '0xFF')))),
                    title: Text(p.name, style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.w500, color: isActive ? theme.primaryColor : null)),
                    onTap: () {
                      ref.read(activeProfileIdProvider.notifier).state = p.id!;
                      Navigator.pop(ctx);
                    },
                  ),
                );
              }),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.add_circle_outline_rounded),
                title: const Text('Create new profile'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showCreateProfileDialog(context, ref);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showCreateProfileDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Profile'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Profile Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              final db = await ref.read(databaseHelperProvider).database;
              final int newId = await db.insert('profiles', {
                'name': controller.text.trim(),
                'icon': '0xe491',
                'color': '#2196F3',
                'is_active': 0,
              });
              ref.invalidate(profilesProvider);
              ref.read(activeProfileIdProvider.notifier).state = newId;
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(BuildContext context, WidgetRef ref, ThemeData theme, bool isDark) {
    final recentAsync = ref.watch(recentTransactionsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final currency = NumberFormat.currency(symbol: currencySymbol);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        recentAsync.when(
          data: (transactions) {
            if (transactions.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text('No recent transactions.', style: TextStyle(color: Colors.grey.shade500)),
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final tx = transactions[index];
                final isExpense = tx.type == 'expense';
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isDark ? AppTheme.neumorphicShadowDark : AppTheme.neumorphicShadowLight,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isExpense ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isExpense ? Icons.arrow_outward_rounded : Icons.arrow_downward_rounded,
                          color: isExpense ? Colors.redAccent : Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tx.merchant, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 2),
                            categoriesAsync.when(
                              data: (categories) {
                                final categoryName = categories.firstWhere(
                                  (c) => c['id'] == tx.categoryId,
                                  orElse: () => {'name': 'Unknown'},
                                )['name'] as String;
                                return Text(
                                  categoryName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isExpense ? Colors.redAccent : Colors.green,
                                  ),
                                );
                              },
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                            const SizedBox(height: 2),
                            Text(DateFormat('MMM dd, yyyy').format(tx.date), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                          ],
                        ),
                      ),
                      Text(
                        '${isExpense ? '-' : '+'}${currency.format(tx.amount)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isExpense ? Colors.redAccent : Colors.green,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Error: $e')),
        ),
      ],
    );
  }
}
