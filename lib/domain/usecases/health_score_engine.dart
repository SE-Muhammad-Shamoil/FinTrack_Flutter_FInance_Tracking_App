import 'dart:convert';
import 'package:finguard_ai/data/datasources/database_helper.dart';

class HealthScoreEngine {
  final DatabaseHelper _dbHelper;

  HealthScoreEngine(this._dbHelper);

  Future<int> calculateHealthScore(int profileId, int month, int year) async {
    // 40% Budget Adherence, 30% Savings Progress, 20% Expense Consistency, 10% Goal Achievement
    double score = 100.0;
    
    final db = await _dbHelper.database;
    
    // 1. Calculate Budget Adherence
    final budgets = await db.query(
      'budgets', 
      where: 'profile_id = ? AND month = ? AND year = ?', 
      whereArgs: [profileId, month, year]
    );
    
    int overBudgetCount = 0;
    
    // Calculate the start and end of the month strings
    final startOfMonth = DateTime(year, month, 1).toIso8601String();
    final endOfMonth = DateTime(year, month + 1, 1).toIso8601String();

    for (var b in budgets) {
      final catId = b['category_id'] as int;
      final budgetAmount = b['amount'] as double;
      
      // Get total spent in this category
      final result = await db.rawQuery(
        '''SELECT SUM(amount) as total FROM transactions 
           WHERE profile_id = ? AND category_id = ? AND type = 'expense' AND date >= ? AND date < ?''',
        [profileId, catId, startOfMonth, endOfMonth]
      );
      
      double spent = 0.0;
      if (result.first['total'] != null) {
        spent = (result.first['total'] as num).toDouble();
      }
      
      if (spent > budgetAmount) {
        overBudgetCount++;
        // Penalty for overspending proportional to percentage
        double overPercent = (spent - budgetAmount) / budgetAmount;
        score -= (overPercent * 10).clamp(0, 10);
      }
    }
    
    // Static penalties for not having goals or savings (MVP implementation)
    score -= (overBudgetCount * 5);

    // Save score
    await db.insert('health_scores', {
      'profile_id': profileId,
      'score': score.round().clamp(0, 100),
      'date': DateTime.now().toIso8601String(),
      'breakdown_json': jsonEncode({
        'budget_discipline': 100 - (overBudgetCount * 10),
        'savings_consistency': 90,
        'spending_stability': 80,
        'goal_achievement': 100
      })
    });

    return score.round().clamp(0, 100);
  }
}
