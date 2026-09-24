import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeflow_app/features/expenses/data/supabase_expense_repository.dart';
import 'package:lifeflow_app/features/expenses/domain/expense.dart';
import 'package:lifeflow_app/features/expenses/domain/expense_repository.dart';
import 'package:lifeflow_app/features/expenses/presentation/expenses_controller.dart';

void main() {
  test('cria, edita e remove despesa', () async {
    final container = ProviderContainer(
      overrides: [expenseRepositoryProvider.overrideWithValue(_Fake())],
    );
    addTearDown(container.dispose);
    final sub = container.listen(
      expensesProvider('vehicle-id'),
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(sub.close);
    await container.read(expensesProvider('vehicle-id').future);
    final controller = container.read(expensesProvider('vehicle-id').notifier);
    final created = await controller.create(_draft(20));
    expect(created.amount, 20);
    await controller.updateExpense(created.id, _draft(30));
    expect(
      container.read(expensesProvider('vehicle-id')).value?.single.amount,
      30,
    );
    await controller.delete(created.id);
    expect(container.read(expensesProvider('vehicle-id')).value, isEmpty);
  });
}

ExpenseDraft _draft(double amount) => ExpenseDraft(
  vehicleId: 'vehicle-id',
  category: ExpenseCategory.toll,
  date: DateTime.utc(2026, 9, 20),
  amount: amount,
  description: 'Pedágio',
);

class _Fake implements ExpenseRepository {
  Expense? value;
  @override
  Future<List<Expense>> getExpenses(String vehicleId) async =>
      value == null ? [] : [value!];
  @override
  Future<Expense> getExpense(String id) async => value!;
  @override
  Future<Expense> saveExpense(String id, ExpenseDraft d) async =>
      value = Expense(
        id: id,
        vehicleId: d.vehicleId,
        category: d.category,
        date: d.date,
        amount: d.amount,
        description: d.description,
        createdAt: d.date,
        updatedAt: d.date,
      );
  @override
  Future<void> deleteExpense(String id) async => value = null;
}
