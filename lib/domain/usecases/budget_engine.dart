import 'package:finguard_ai/data/datasources/database_helper.dart';

class BudgetEngine {
  final DatabaseHelper _dbHelper;

  BudgetEngine(this._dbHelper);

  Future<Map<String, dynamic>> checkBudgetStatus(int categoryId, int month, int year) async {
    final db = await _dbHelper.database;
    
    // Get budget for the category
    final budgetRes = await db.query(
      'budgets',
      where: 'category_id = ? AND month = ? AND year = ?',
      whereArgs: [categoryId, month, year],
    );

    if (budgetRes.isEmpty) {
      return {'status': 'no_budget'};
    }

    final double budgetAmount = budgetRes.first['amount'] as double;

    // Get total spending for this category in this month
    final startOfMonth = DateTime(year, month, 1).toIso8601String();
    final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String();

    final spendingRes = await db.rawQuery('''
      SELECT SUM(amount) as total 
      FROM transactions 
      WHERE category_id = ? 
      AND type = 'debit'
      AND date >= ? 
      AND date <= ?
    ''', [categoryId, startOfMonth, endOfMonth]);

    final double spentAmount = (spendingRes.first['total'] as double?) ?? 0.0;
    final double remaining = budgetAmount - spentAmount;
    final double percentageUsed = (spentAmount / budgetAmount) * 100;

    return {
      'status': 'active',
      'budget': budgetAmount,
      'spent': spentAmount,
      'remaining': remaining,
      'percentage_used': percentageUsed,
      'is_over_budget': remaining < 0,
    };
  }
}
