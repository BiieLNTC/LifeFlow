import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeflow_app/features/finance/data/supabase_budget_repository.dart';
import 'package:lifeflow_app/features/finance/domain/budget.dart';
import 'package:lifeflow_app/features/finance/domain/budget_repository.dart';
import 'package:lifeflow_app/features/finance/presentation/budgets_controller.dart';

void main() {
  test('cria, edita e remove orçamento', () async {
    final container = ProviderContainer(
      overrides: [budgetRepositoryProvider.overrideWithValue(_Fake())],
    );
    addTearDown(container.dispose);
    await container.read(budgetsControllerProvider.future);
    final controller = container.read(budgetsControllerProvider.notifier);

    final created = await controller.create(_draft(500));
    expect(created.limitAmount, 500);

    await controller.updateBudget(created.id, _draft(600));
    expect(
      container.read(budgetsControllerProvider).value?.single.limitAmount,
      600,
    );

    await controller.delete(created.id);
    expect(container.read(budgetsControllerProvider).value, isEmpty);
  });
}

BudgetDraft _draft(double limitAmount) => BudgetDraft(
  categoryId: 'category-id',
  year: 2026,
  month: 9,
  limitAmount: limitAmount,
);

class _Fake implements BudgetRepository {
  Budget? value;

  @override
  Future<List<Budget>> getBudgets() async => value == null ? [] : [value!];

  @override
  Future<Budget> getBudget(String id) async => value!;

  @override
  Future<Budget> saveBudget(String id, BudgetDraft draft) async =>
      value = Budget(
        id: id,
        categoryId: draft.categoryId,
        year: draft.year,
        month: draft.month,
        limitAmount: draft.limitAmount,
        createdAt: DateTime.utc(2026, 9, 20),
        updatedAt: DateTime.utc(2026, 9, 20),
      );

  @override
  Future<void> deleteBudget(String id) async => value = null;
}
