import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeflow_app/features/expenses/data/supabase_expense_repository.dart';
import 'package:lifeflow_app/features/expenses/domain/expense.dart';
import 'package:uuid/uuid.dart';

final expensesProvider =
    AsyncNotifierProvider.family<ExpensesController, List<Expense>, String>(
      ExpensesController.new,
    );
final expenseDetailsProvider = FutureProvider.family<Expense, String>(
  (ref, id) => ref.watch(expenseRepositoryProvider).getExpense(id),
);

class ExpensesController extends AsyncNotifier<List<Expense>> {
  ExpensesController(this.vehicleId);
  final String vehicleId;
  final uuid = const Uuid();
  @override
  Future<List<Expense>> build() =>
      ref.watch(expenseRepositoryProvider).getExpenses(vehicleId);
  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(expenseRepositoryProvider).getExpenses(vehicleId),
    );
  }

  Future<Expense> create(ExpenseDraft d) async {
    final x = await ref
        .read(expenseRepositoryProvider)
        .saveExpense(uuid.v7(), d);
    state = AsyncData([x, ...?state.value]);
    return x;
  }

  Future<Expense> updateExpense(String id, ExpenseDraft d) async {
    final x = await ref.read(expenseRepositoryProvider).saveExpense(id, d);
    state = AsyncData([
      for (final e in state.value ?? const <Expense>[])
        if (e.id == id) x else e,
    ]);
    ref.invalidate(expenseDetailsProvider(id));
    return x;
  }

  Future<void> delete(String id) async {
    await ref.read(expenseRepositoryProvider).deleteExpense(id);
    state = AsyncData(
      (state.value ?? const <Expense>[]).where((x) => x.id != id).toList(),
    );
    ref.invalidate(expenseDetailsProvider(id));
  }
}
