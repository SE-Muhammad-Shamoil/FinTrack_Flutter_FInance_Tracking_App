import 'dart:convert';
import 'package:finguard_ai/data/datasources/database_helper.dart';

class TransactionCategorizer {
  final DatabaseHelper _dbHelper;

  TransactionCategorizer(this._dbHelper);

  /// Analyzes the merchant string and returns the matching category_id
  Future<int> categorize(String merchant) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> categories = await db.query('categories');

    final normalizedMerchant = merchant.toLowerCase();

    for (var category in categories) {
      final String mappingsJson = category['keyword_mappings'];
      final List<dynamic> mappings = jsonDecode(mappingsJson);
      
      for (var keyword in mappings) {
        if (normalizedMerchant.contains(keyword.toString().toLowerCase())) {
          return category['id'] as int;
        }
      }
    }
    
    // Fallback: If no match is found, return the ID of a default 'Uncategorized' or 'Others' category.
    // Assuming category ID 1 is Food and maybe there's a generic one. For now, returning 1 as fallback or null
    // Let's assume we create an 'Others' category dynamically or it's ID 0. 
    return 1; // Fallback to Food for testing, should ideally be 'Uncategorized'
  }

  /// Learns from user corrections
  Future<void> learnCorrection(int categoryId, String newKeyword) async {
    final db = await _dbHelper.database;
    
    final List<Map<String, dynamic>> categoryRes = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [categoryId],
    );

    if (categoryRes.isNotEmpty) {
      final category = categoryRes.first;
      final List<dynamic> mappings = jsonDecode(category['keyword_mappings']);
      
      if (!mappings.contains(newKeyword.toLowerCase())) {
        mappings.add(newKeyword.toLowerCase());
        
        await db.update(
          'categories',
          {'keyword_mappings': jsonEncode(mappings)},
          where: 'id = ?',
          whereArgs: [categoryId],
        );
      }
    }
  }
}
