enum ExpenseCategory {
  fuel('fuel', 'Combustível'),
  maintenance('maintenance', 'Manutenção'),
  insurance('insurance', 'Seguro'),
  ipva('ipva', 'IPVA'),
  licensing('licensing', 'Licenciamento'),
  fine('fine', 'Multa'),
  toll('toll', 'Pedágio'),
  parking('parking', 'Estacionamento'),
  carWash('car_wash', 'Lavagem'),
  accessories('accessories', 'Acessórios'),
  tires('tires', 'Pneus'),
  other('other', 'Outros');

  const ExpenseCategory(this.databaseValue, this.label);
  final String databaseValue, label;
  static ExpenseCategory fromDatabase(String value) =>
      values.firstWhere((x) => x.databaseValue == value);
}

class Expense {
  const Expense({
    required this.id,
    required this.vehicleId,
    required this.category,
    required this.date,
    required this.amount,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
  });
  final String id, vehicleId, description;
  final ExpenseCategory category;
  final DateTime date, createdAt, updatedAt;
  final double amount;
  final String? notes;
}

class ExpenseDraft {
  const ExpenseDraft({
    required this.vehicleId,
    required this.category,
    required this.date,
    required this.amount,
    required this.description,
    this.notes,
  });
  final String vehicleId, description;
  final ExpenseCategory category;
  final DateTime date;
  final double amount;
  final String? notes;
}
