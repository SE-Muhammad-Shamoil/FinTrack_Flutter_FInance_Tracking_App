import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finguard_ai/core/theme/app_theme.dart';
import 'package:finguard_ai/presentation/providers/app_providers.dart';
import 'package:intl/intl.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String _activeFilter = 'All';
  String _searchQuery = '';

  Future<void> _deleteTransaction(int id) async {
    final db = await ref.read(databaseHelperProvider).database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
    ref.invalidate(filteredTransactionsProvider);
    ref.invalidate(recentTransactionsProvider);
    ref.invalidate(categorySpendingProvider);
    ref.invalidate(monthlyBudgetProgressProvider);
    ref.invalidate(totalIncomeProvider);
    ref.invalidate(totalSpendingProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24).copyWith(bottom: 120),
          children: [
            _buildHeader(theme),
            const SizedBox(height: 24),
            _buildSearchBar(theme, isDark),
            const SizedBox(height: 24),
            _buildFilters(theme),
            const SizedBox(height: 24),
            _buildTransactionList(theme, isDark),
            const SizedBox(height: 32),
            _buildTransactionSummary(theme, isDark),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.primaryColor,
        child: const Icon(Icons.add_rounded, color: Colors.white),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (ctx) => const _AddTransactionModal(),
          );
        },
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transactions',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'View and manage your spendings and investments',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? AppTheme.neumorphicShadowDark : AppTheme.neumorphicShadowLight,
      ),
      child: TextField(
        onChanged: (val) {
          setState(() {
            _searchQuery = val.toLowerCase();
          });
        },
        decoration: const InputDecoration(
          hintText: 'Search transactions',
          hintStyle: TextStyle(color: Colors.grey),
          border: InputBorder.none,
          icon: Icon(Icons.search_rounded, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildFilters(ThemeData theme) {
    final filters = ['All', 'Spending', 'Income'];
    return Row(
      children: filters.map((f) {
        final isActive = _activeFilter == f;
        return GestureDetector(
          onTap: () => setState(() => _activeFilter = f),
          child: Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Text(
              f,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? theme.primaryColor : Colors.grey.shade500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTransactionList(ThemeData theme, bool isDark) {
    final transactionsAsync = ref.watch(filteredTransactionsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);
    
    return transactionsAsync.when(
      data: (transactions) {
        var filteredTransactions = transactions;
        if (_activeFilter == 'Spending') {
          filteredTransactions = filteredTransactions.where((t) => t.type == 'expense').toList();
        } else if (_activeFilter == 'Income') {
          filteredTransactions = filteredTransactions.where((t) => t.type == 'income').toList();
        }

        if (_searchQuery.isNotEmpty) {
          filteredTransactions = filteredTransactions.where((t) {
            final categoryName = categoriesAsync.value?.firstWhere(
              (c) => c['id'] == t.categoryId,
              orElse: () => {'name': ''},
            )['name'] as String;
            
            return t.merchant.toLowerCase().contains(_searchQuery) ||
                   categoryName.toLowerCase().contains(_searchQuery);
          }).toList();
        }

        if (filteredTransactions.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('No transactions found.', style: TextStyle(color: Colors.grey))),
          );
        }
        return Column(
          children: filteredTransactions.map((t) {
            final isExpense = t.type == 'expense';
            return Dismissible(
              key: ValueKey(t.id),
              direction: DismissDirection.endToStart,
              background: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.centerRight,
                child: const Icon(Icons.delete_rounded, color: Colors.white),
              ),
              onDismissed: (_) {
                _deleteTransaction(t.id!);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction deleted')));
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
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
                      color: (isExpense ? Colors.orange : Colors.blue).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(isExpense ? Icons.shopping_bag : Icons.savings, color: isExpense ? Colors.orange : Colors.blue, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.merchant,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        categoriesAsync.when(
                          data: (categories) {
                            final categoryName = categories.firstWhere(
                              (c) => c['id'] == t.categoryId,
                              orElse: () => {'name': 'Unknown'},
                            )['name'] as String;
                            return Text(
                              categoryName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isExpense ? Colors.orange : Colors.blue,
                              ),
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('MMM dd, yyyy, h:mm a').format(t.date),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$currencySymbol${t.amount.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                    onPressed: () {
                      _deleteTransaction(t.id!);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction deleted')));
                    },
                  ),
                ],
              ),
            ));
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildTransactionSummary(ThemeData theme, bool isDark) {
    final transactionsAsync = ref.watch(filteredTransactionsProvider);
    
    return transactionsAsync.when(
      data: (transactions) {
        double spending = 0;
        double income = 0;
        for (var t in transactions) {
          if (t.type == 'expense') spending += t.amount;
          if (t.type == 'income') income += t.amount;
        }

        if (spending == 0 && income == 0) return const SizedBox.shrink();

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Transaction Summary',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Spent', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade500)),
                        const SizedBox(height: 4),
                        Text(
                          currency.format(spending),
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.redAccent),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Income', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade500)),
                        const SizedBox(height: 4),
                        Text(
                          currency.format(income),
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
    );
  }
}

class _AddTransactionModal extends ConsumerStatefulWidget {
  const _AddTransactionModal();

  @override
  ConsumerState<_AddTransactionModal> createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends ConsumerState<_AddTransactionModal> {
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  String _type = 'expense';
  int? _selectedCategoryId;

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text);
    final merchant = _merchantController.text.trim();
    int? categoryIdToUse = _selectedCategoryId;
    if (_type == 'income') {
      final categories = ref.read(categoriesProvider).value;
      if (categories != null) {
        final incomeCats = categories.where((c) => c['type'] == 'income');
        if (incomeCats.isNotEmpty) {
          categoryIdToUse = incomeCats.first['id'] as int;
        }
      }
    }

    if (amount == null || amount <= 0 || merchant.isEmpty || categoryIdToUse == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    final db = await ref.read(databaseHelperProvider).database;
    final profileId = ref.read(activeProfileIdProvider);

    await db.insert('transactions', {
      'profile_id': profileId,
      'category_id': categoryIdToUse,
      'amount': amount,
      'merchant': merchant,
      'date': DateTime.now().toIso8601String(),
      'type': _type,
      'sms_body': 'Manual entry',
      'account_name': 'Cash',
    });

    ref.invalidate(filteredTransactionsProvider);
    ref.invalidate(monthlyBudgetProgressProvider);
    ref.invalidate(totalIncomeProvider);
    ref.invalidate(totalSpendingProvider);
    ref.invalidate(categorySpendingProvider);
    ref.invalidate(recentTransactionsProvider);
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
    final currencySymbol = ref.watch(currencySymbolProvider);

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
          Text('Add Transaction', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Expense'),
                  value: 'expense',
                  groupValue: _type,
                  onChanged: (val) => setState(() => _type = val!),
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Income'),
                  value: 'income',
                  groupValue: _type,
                  onChanged: (val) => setState(() => _type = val!),
                ),
              ),
            ],
          ),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Amount ($currencySymbol)', border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _merchantController,
            decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          if (_type == 'expense')
            categoriesAsync.when(
              data: (categories) {
                final relevantCategories = categories.where((c) => c['type'] == 'expense').toList();
                
                // Validate if selected category still exists in the list
                bool selectedIsValid = _selectedCategoryId == null || relevantCategories.any((c) => c['id'] == _selectedCategoryId);

                return DropdownButtonFormField<int>(
                  value: selectedIsValid ? _selectedCategoryId : null,
                  decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                  items: [
                    ...relevantCategories.map((c) {
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
            )
          else
            const SizedBox.shrink(),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Save Transaction', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

