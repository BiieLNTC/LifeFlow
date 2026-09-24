import 'package:lifeflow_app/features/finance/domain/transaction.dart';

class RecurringTransaction {
  const RecurringTransaction({
    required this.id,
    required this.categoryId,
    required this.description,
    required this.type,
    required this.amount,
    required this.dayOfMonth,
    required this.startDate,
    required this.paused,
    required this.createdAt,
    required this.updatedAt,
    this.personId,
    this.endDate,
  });
  final String id, categoryId, description;
  final String? personId;
  final TransactionType type;
  final double amount;
  final int dayOfMonth;
  final DateTime startDate, createdAt, updatedAt;
  final DateTime? endDate;
  final bool paused;
}

class RecurringTransactionDraft {
  const RecurringTransactionDraft({
    required this.categoryId,
    required this.description,
    required this.type,
    required this.amount,
    required this.dayOfMonth,
    required this.startDate,
    this.personId,
    this.endDate,
    this.paused = false,
  });
  final String categoryId, description;
  final String? personId;
  final TransactionType type;
  final double amount;
  final int dayOfMonth;
  final DateTime startDate;
  final DateTime? endDate;
  final bool paused;
}
