import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:finguard_ai/data/datasources/database_helper.dart';
import 'package:finguard_ai/domain/usecases/transaction_categorizer.dart';
import 'package:finguard_ai/domain/usecases/budget_engine.dart';
import 'package:finguard_ai/domain/usecases/health_score_engine.dart';
import 'package:finguard_ai/services/sms/sms_parser_service.dart';
import 'package:finguard_ai/domain/entities/profile.dart';
import 'package:finguard_ai/domain/entities/transaction.dart' as entity;
import 'package:finguard_ai/domain/entities/transaction_filter.dart';
import 'package:finguard_ai/domain/entities/investment.dart';
import 'package:finguard_ai/domain/entities/portfolio_history.dart';

// Database Provider
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

// Services Providers
final smsParserServiceProvider = Provider<SmsParserService>((ref) {
  return SmsParserService();
});

// Engines / Use Cases Providers
final transactionCategorizerProvider = Provider<TransactionCategorizer>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return TransactionCategorizer(dbHelper);
});

final budgetEngineProvider = Provider<BudgetEngine>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return BudgetEngine(dbHelper);
});

final healthScoreEngineProvider = Provider<HealthScoreEngine>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return HealthScoreEngine(dbHelper);
});

// ======================== STATE PROVIDERS ========================

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

// 1. Profile & Settings State
final activeProfileIdProvider = StateProvider<int>((ref) => 1); // Default to Profile 1
final currencySymbolProvider = StateProvider<String>((ref) => '\$'); // Default currency symbol

final profilesProvider = FutureProvider<List<Profile>>((ref) async {
  final db = await ref.watch(databaseHelperProvider).database;
  final maps = await db.query('profiles');
  return maps.map((e) => Profile.fromMap(e)).toList();
});

// 2. Transaction Filters State
final transactionFilterProvider = StateProvider<TransactionFilter>((ref) => TransactionFilter());

// 3. Transactions List (Filtered)
final filteredTransactionsProvider = FutureProvider<List<entity.Transaction>>((ref) async {
  final db = await ref.watch(databaseHelperProvider).database;
  final profileId = ref.watch(activeProfileIdProvider);
  final filter = ref.watch(transactionFilterProvider);

  String whereString = 'profile_id = ?';
  List<dynamic> whereArgs = [profileId];

  if (filter.categoryId != null) {
    whereString += ' AND category_id = ?';
    whereArgs.add(filter.categoryId);
  }
  if (filter.type != null && filter.type!.isNotEmpty) {
    whereString += ' AND type = ?';
    whereArgs.add(filter.type);
  }
  if (filter.startDate != null) {
    whereString += ' AND date >= ?';
    whereArgs.add(filter.startDate!.toIso8601String());
  }
  if (filter.endDate != null) {
    whereString += ' AND date <= ?';
    whereArgs.add(filter.endDate!.toIso8601String());
  }

  String orderBy = 'date DESC';
  if (filter.sortOrder == 'date_asc') orderBy = 'date ASC';
  if (filter.sortOrder == 'amount_desc') orderBy = 'amount DESC';
  if (filter.sortOrder == 'amount_asc') orderBy = 'amount ASC';

  final maps = await db.query(
    'transactions',
    where: whereString,
    whereArgs: whereArgs,
    orderBy: orderBy,
  );
  
  return maps.map((e) => entity.Transaction.fromMap(e)).toList();
});

// 4. Dashboard Stats
final recentTransactionsProvider = FutureProvider<List<entity.Transaction>>((ref) async {
  final db = await ref.watch(databaseHelperProvider).database;
  final profileId = ref.watch(activeProfileIdProvider);
  
  final maps = await db.query(
    'transactions',
    where: 'profile_id = ?',
    whereArgs: [profileId],
    orderBy: 'date DESC',
    limit: 5,
  );
  return maps.map((e) => entity.Transaction.fromMap(e)).toList();
});

final totalSpendingProvider = FutureProvider<double>((ref) async {
  final db = await ref.watch(databaseHelperProvider).database;
  final profileId = ref.watch(activeProfileIdProvider);
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();
  
  final result = await db.rawQuery(
    '''SELECT SUM(amount) as total FROM transactions 
       WHERE profile_id = ? AND type = "expense" AND date >= ?''',
    [profileId, startOfMonth]
  );
  
  if (result.first['total'] != null) {
    return (result.first['total'] as num).toDouble();
  }
  return 0.0;
});

final totalIncomeProvider = FutureProvider<double>((ref) async {
  final db = await ref.watch(databaseHelperProvider).database;
  final profileId = ref.watch(activeProfileIdProvider);
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();
  
  final result = await db.rawQuery(
    '''SELECT SUM(amount) as total FROM transactions 
       WHERE profile_id = ? AND type = "income" AND date >= ?''',
    [profileId, startOfMonth]
  );
  
  if (result.first['total'] != null) {
    return (result.first['total'] as num).toDouble();
  }
  return 0.0;
});

final currentHealthScoreProvider = FutureProvider<int>((ref) async {
  final engine = ref.watch(healthScoreEngineProvider);
  final profileId = ref.watch(activeProfileIdProvider);
  final now = DateTime.now();
  return await engine.calculateHealthScore(profileId, now.month, now.year);
});

// 5. Budgets Progress
final monthlyBudgetProgressProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = await ref.watch(databaseHelperProvider).database;
  final profileId = ref.watch(activeProfileIdProvider);
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();
  final endOfMonth = DateTime(now.year, now.month + 1, 1).toIso8601String();

  final budgets = await db.query(
    'budgets',
    where: 'profile_id = ? AND month = ? AND year = ?',
    whereArgs: [profileId, now.month, now.year]
  );

  List<Map<String, dynamic>> progressList = [];

  for (var b in budgets) {
    final catId = b['category_id'] as int;
    final budgetAmount = b['amount'] as double;
    
    // Get Category Info
    final catData = await db.query('categories', where: 'id = ?', whereArgs: [catId]);
    if (catData.isEmpty) continue;
    final category = catData.first;

    // Get Spending
    final spendingData = await db.rawQuery(
      '''SELECT SUM(amount) as total FROM transactions 
         WHERE profile_id = ? AND category_id = ? AND type = 'expense' AND date >= ? AND date < ?''',
      [profileId, catId, startOfMonth, endOfMonth]
    );

    double spent = 0.0;
    if (spendingData.first['total'] != null) {
      spent = (spendingData.first['total'] as num).toDouble();
    }

    progressList.add({
      'category_name': category['name'],
      'color': category['color'],
      'icon': category['icon'],
      'budget': budgetAmount,
      'spent': spent,
      'percentage': (spent / budgetAmount).clamp(0.0, 1.0),
      'isOver': spent > budgetAmount
    });
  }

  return progressList;
});

final categorySpendingProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = await ref.watch(databaseHelperProvider).database;
  final profileId = ref.watch(activeProfileIdProvider);
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();
  final endOfMonth = DateTime(now.year, now.month + 1, 1).toIso8601String();

  final result = await db.rawQuery(
    '''
    SELECT c.name as category_name, c.color as color, c.icon as icon, SUM(t.amount) as spent
    FROM transactions t
    JOIN categories c ON t.category_id = c.id
    WHERE t.profile_id = ? AND t.type = 'expense' AND t.date >= ? AND t.date < ?
    GROUP BY c.id
    HAVING spent > 0
    ORDER BY spent DESC
    ''',
    [profileId, startOfMonth, endOfMonth]
  );
  return result;
});

// 6. Categories Provider
final categoriesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = await ref.watch(databaseHelperProvider).database;
  final profileId = ref.watch(activeProfileIdProvider);
  return await db.query('categories', where: 'profile_id = ?', whereArgs: [profileId]);
});

// 7. Investments Provider
final investmentsProvider = FutureProvider<List<Investment>>((ref) async {
  final db = await ref.watch(databaseHelperProvider).database;
  final profileId = ref.watch(activeProfileIdProvider);
  final maps = await db.query('investments', where: 'profile_id = ?', whereArgs: [profileId]);
  return maps.map((e) => Investment.fromMap(e)).toList();
});

// 8. Portfolio History Provider
final portfolioHistoryProvider = FutureProvider<List<PortfolioHistory>>((ref) async {
  final db = await ref.watch(databaseHelperProvider).database;
  final profileId = ref.watch(activeProfileIdProvider);
  final maps = await db.query('portfolio_history', where: 'profile_id = ?', whereArgs: [profileId], orderBy: 'date ASC');
  return maps.map((e) => PortfolioHistory.fromMap(e)).toList();
});
