class Budget {
  const Budget({
    required this.id,
    required this.categoryId,
    required this.year,
    required this.month,
    required this.limitAmount,
    required this.createdAt,
    required this.updatedAt,
  });
  final String id, categoryId;
  final int year, month;
  final double limitAmount;
  final DateTime createdAt, updatedAt;
}

class BudgetDraft {
  const BudgetDraft({
    required this.categoryId,
    required this.year,
    required this.month,
    required this.limitAmount,
  });
  final String categoryId;
  final int year, month;
  final double limitAmount;
}
