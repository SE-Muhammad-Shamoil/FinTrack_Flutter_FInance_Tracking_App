import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:finguard_ai/data/datasources/database_helper.dart';

class ExportService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> exportTransactionsToCsv(int profileId) async {
    try {
      final db = await _dbHelper.database;
      final transactions = await db.query('transactions', where: 'profile_id = ?', whereArgs: [profileId]);

      if (transactions.isEmpty) {
        return; // No data to export
      }

      List<String> rows = [];
      // Headers
      rows.add("ID,Date,Merchant,Amount,Type,Account Name");

      for (var tx in transactions) {
        // Simple manual CSV string escaping
        final merchant = tx['merchant'].toString().replaceAll(',', '');
        final accountName = tx['account_name'].toString().replaceAll(',', '');
        
        rows.add([
          tx['id'],
          tx['date'],
          merchant,
          tx['amount'],
          tx['type'],
          accountName
        ].join(','));
      }

      String csv = rows.join('\n');

      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/finguard_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsString(csv);

      await Share.shareXFiles([XFile(path)], text: 'My FinGuard Transactions Backup');

    } catch (e) {
      // Handle error quietly
    }
  }
}
