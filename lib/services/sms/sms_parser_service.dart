import 'package:finguard_ai/domain/entities/transaction.dart';

abstract class BankSmsParser {
  bool isMatch(String sender, String body);
  ParsedTransaction? parse(String sender, String body);
}

class GenericBankParser implements BankSmsParser {
  @override
  bool isMatch(String sender, String body) {
    final lowerSender = sender.toLowerCase();
    final lowerBody = body.toLowerCase();
    return lowerSender.contains('meezan') || 
           lowerSender.contains('hbl') || 
           lowerSender.contains('alfalah') || 
           lowerSender.contains('scb') || 
           lowerSender.contains('ubl') ||
           lowerSender.contains('allied') ||
           lowerBody.contains('account') ||
           lowerBody.contains('a/c');
  }

  @override
  ParsedTransaction? parse(String sender, String body) {
    // 1. Extract Amount
    final amountRegex = RegExp(r'(?:Rs\.?|PKR)\s*([\d,]+\.?\d*)', caseSensitive: false);
    final amountMatch = amountRegex.firstMatch(body);
    
    // 2. Extract Type (Debit/Credit)
    final typeRegex = RegExp(r'\b(debited|credited|paid|transferred|withdrawn|purchase|deposited)\b', caseSensitive: false);
    final typeMatch = typeRegex.firstMatch(body);

    if (amountMatch != null && typeMatch != null) {
      final amountStr = amountMatch.group(1)?.replaceAll(',', '') ?? '0';
      final amount = double.tryParse(amountStr) ?? 0.0;
      final typeStr = typeMatch.group(1)?.toLowerCase() ?? '';
      
      final type = (typeStr == 'debited' || typeStr == 'paid' || typeStr == 'withdrawn' || typeStr == 'purchase' || typeStr == 'transferred') 
          ? 'expense' 
          : 'income';
      
      // 3. Extract Merchant/Recipient
      // Look for text after 'to', 'at', 'via', or 'from'
      String merchant = 'Unknown Merchant';
      final merchantRegex = RegExp(r'(?:to|at|via|from)\s+([A-Za-z0-9\s*.\-]+?)(?:\s+on|\s+avail|\.|$)', caseSensitive: false);
      final merchantMatch = merchantRegex.firstMatch(body);
      
      if (merchantMatch != null && merchantMatch.group(1) != null) {
        final extracted = merchantMatch.group(1)!.trim();
        // Ignore generic words that might get caught
        if (extracted.toLowerCase() != 'your account' && extracted.toLowerCase() != 'a/c') {
            merchant = extracted;
        }
      }

      return ParsedTransaction(
        amount: amount,
        merchant: merchant,
        date: DateTime.now().toIso8601String(), // We will map real dates in future if needed
        type: type,
        accountName: sender.toUpperCase(), // Using sender ID as Account Name
        smsBody: body,
      );
    }
    return null;
  }
}

class SmsParserService {
  final List<BankSmsParser> _parsers = [
    GenericBankParser(),
  ];

  ParsedTransaction? parseSms(String sender, String body) {
    for (var parser in _parsers) {
      if (parser.isMatch(sender, body)) {
        final result = parser.parse(sender, body);
        if (result != null) return result;
      }
    }
    return null; // Not a recognized financial SMS
  }
}

class ParsedTransaction {
  final double amount;
  final String merchant;
  final String date;
  final String type;
  final String accountName;
  final String smsBody;

  ParsedTransaction({
    required this.amount,
    required this.merchant,
    required this.date,
    required this.type,
    required this.accountName,
    required this.smsBody,
  });
}
