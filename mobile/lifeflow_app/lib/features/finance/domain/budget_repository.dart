import 'package:lifeflow_app/features/finance/domain/budget.dart';

class BudgetFailure implements Exception {
  const BudgetFailure(this.message);
  final String message;
}

abstract interface class BudgetRepository {
  Future<List<Budget>> getBudgets();
  Future<Budget> getBudget(String id);
  Future<Budget> saveBudget(String id, BudgetDraft draft);
  Future<void> deleteBudget(String id);
}
