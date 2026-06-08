class Investment {
  final int? id;
  final int profileId;
  final String ticker;
  final String name;
  final double shares;
  final double currentPrice;
  final String assetClass;

  Investment({
    this.id,
    required this.profileId,
    required this.ticker,
    required this.name,
    required this.shares,
    required this.currentPrice,
    required this.assetClass,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profile_id': profileId,
      'ticker': ticker,
      'name': name,
      'shares': shares,
      'current_price': currentPrice,
      'asset_class': assetClass,
    };
  }

  factory Investment.fromMap(Map<String, dynamic> map) {
    return Investment(
      id: map['id'],
      profileId: map['profile_id'],
      ticker: map['ticker'],
      name: map['name'],
      shares: map['shares'],
      currentPrice: map['current_price'],
      assetClass: map['asset_class'],
    );
  }
}
