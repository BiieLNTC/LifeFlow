import 'package:lifeflow_app/features/expenses/domain/expense.dart';

class ExpenseFailure implements Exception {
  const ExpenseFailure(this.message);
  final String message;
}

abstract interface class ExpenseRepository {
  Future<List<Expense>> getExpenses(String vehicleId);
  Future<Expense> getExpense(String id);
  Future<Expense> saveExpense(String id, ExpenseDraft draft);
  Future<void> deleteExpense(String id);
}
