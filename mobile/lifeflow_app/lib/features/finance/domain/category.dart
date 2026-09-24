enum CategoryPurpose {
  expense('expense', 'Despesa'),
  income('income', 'Receita'),
  both('both', 'Ambos');

  const CategoryPurpose(this.databaseValue, this.label);
  final String databaseValue, label;
  static CategoryPurpose fromDatabase(String value) =>
      values.firstWhere((x) => x.databaseValue == value);
}

class Category {
  const Category({
    required this.id,
    required this.description,
    required this.purpose,
    required this.createdAt,
    required this.updatedAt,
    this.color,
  });
  final String id, description;
  final CategoryPurpose purpose;
  final String? color;
  final DateTime createdAt, updatedAt;
}

class CategoryDraft {
  const CategoryDraft({
    required this.description,
    required this.purpose,
    this.color,
  });
  final String description;
  final CategoryPurpose purpose;
  final String? color;
}
