class PortfolioHistory {
  final int? id;
  final int profileId;
  final DateTime date;
  final double totalValue;

  PortfolioHistory({
    this.id,
    required this.profileId,
    required this.date,
    required this.totalValue,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profile_id': profileId,
      'date': date.toIso8601String(),
      'total_value': totalValue,
    };
  }

  factory PortfolioHistory.fromMap(Map<String, dynamic> map) {
    return PortfolioHistory(
      id: map['id'],
      profileId: map['profile_id'],
      date: DateTime.parse(map['date']),
      totalValue: map['total_value'],
    );
  }
}
