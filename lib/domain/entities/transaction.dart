class Transaction {
  final int? id;
  final int profileId;
  final String smsBody;
  final double amount;
  final String merchant;
  final int categoryId;
  final DateTime date;
  final String type; // 'credit' or 'debit'
  final String accountName;

  Transaction({
    this.id,
    required this.profileId,
    required this.smsBody,
    required this.amount,
    required this.merchant,
    required this.categoryId,
    required this.date,
    required this.type,
    required this.accountName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profile_id': profileId,
      'sms_body': smsBody,
      'amount': amount,
      'merchant': merchant,
      'category_id': categoryId,
      'date': date.toIso8601String(),
      'type': type,
      'account_name': accountName,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      profileId: map['profile_id'] ?? 1,
      smsBody: map['sms_body'],
      amount: map['amount'],
      merchant: map['merchant'],
      categoryId: map['category_id'],
      date: DateTime.parse(map['date']),
      type: map['type'],
      accountName: map['account_name'],
    );
  }
}
