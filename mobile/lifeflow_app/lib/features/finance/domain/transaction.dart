enum TransactionType {
  expense('expense', 'Despesa'),
  income('income', 'Receita');

  const TransactionType(this.databaseValue, this.label);
  final String databaseValue, label;
  static TransactionType fromDatabase(String value) =>
      values.firstWhere((x) => x.databaseValue == value);
}

/// Origem quando a transação foi gerada automaticamente a partir de um
/// registro de veículo ou de uma recorrência. Quando não nulo, a transação
/// não é editável/excluível pelo client de finanças (ver RLS).
enum TransactionSource {
  maintenance('maintenance'),
  refueling('refueling'),
  vehicleExpense('vehicle_expense'),
  recurring('recurring');

  const TransactionSource(this.databaseValue);
  final String databaseValue;
  static TransactionSource fromDatabase(String value) =>
      values.firstWhere((x) => x.databaseValue == value);
}

class Transaction {
  const Transaction({
    required this.id,
    required this.categoryId,
    required this.transactionDate,
    required this.description,
    required this.type,
    required this.amount,
    required this.createdAt,
    required this.updatedAt,
    this.personId,
    this.source,
    this.sourceId,
    this.installmentGroupId,
    this.installmentIndex,
    this.installmentTotal,
  });
  final String id, categoryId, description;
  final String? personId, sourceId, installmentGroupId;
  final TransactionType type;
  final TransactionSource? source;
  final DateTime transactionDate, createdAt, updatedAt;
  final double amount;
  final int? installmentIndex, installmentTotal;

  bool get isEditable => source == null;
}

class TransactionDraft {
  const TransactionDraft({
    required this.categoryId,
    required this.transactionDate,
    required this.description,
    required this.type,
    required this.amount,
    this.personId,
  });
  final String categoryId, description;
  final String? personId;
  final TransactionType type;
  final DateTime transactionDate;
  final double amount;
}
