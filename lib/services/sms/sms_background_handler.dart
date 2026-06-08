import 'package:telephony/telephony.dart';
import 'package:finguard_ai/data/datasources/database_helper.dart';
import 'package:finguard_ai/services/sms/sms_parser_service.dart';
import 'package:finguard_ai/domain/usecases/transaction_categorizer.dart';
import 'package:finguard_ai/services/notification/notification_service.dart';

@pragma('vm:entry-point')
backgroundMessageHandler(SmsMessage message) async {
  // Handle background SMS processing
  final parser = SmsParserService();
  final dbHelper = DatabaseHelper.instance;
  final categorizer = TransactionCategorizer(dbHelper);
  final notificationService = NotificationService();
  
  await notificationService.init();

  final sender = message.address ?? '';
  final body = message.body ?? '';

  final parsedTx = parser.parseSms(sender, body);

  if (parsedTx != null) {
    // Found a valid financial transaction, let's categorize it
    final categoryId = await categorizer.categorize(parsedTx.merchant);

    // Get active profile
    final db = await dbHelper.database;
    int profileId = 1;
    final profileResult = await db.query('profiles', where: 'is_active = 1', limit: 1);
    if (profileResult.isNotEmpty) {
      profileId = profileResult.first['id'] as int;
    }

    // Save to DB
    await db.insert('transactions', {
      'profile_id': profileId,
      'sms_body': parsedTx.smsBody,
      'amount': parsedTx.amount,
      'merchant': parsedTx.merchant,
      'category_id': categoryId,
      'date': parsedTx.date,
      'type': parsedTx.type,
      'account_name': parsedTx.accountName,
    });

    // Send a local notification to inform the user
    await notificationService.showNotification(
      title: 'New Transaction Tracked',
      body: '${parsedTx.type == 'debit' ? '-' : '+'}Rs. ${parsedTx.amount} at ${parsedTx.merchant}',
    );
  }
}
