class TransactionFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final int? categoryId;
  final String? type; // 'income' or 'expense'
  final String? sortOrder; // 'date_desc', 'date_asc', 'amount_desc', 'amount_asc'

  TransactionFilter({
    this.startDate,
    this.endDate,
    this.categoryId,
    this.type,
    this.sortOrder = 'date_desc',
  });

  TransactionFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    int? categoryId,
    String? type,
    String? sortOrder,
  }) {
    return TransactionFilter(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
