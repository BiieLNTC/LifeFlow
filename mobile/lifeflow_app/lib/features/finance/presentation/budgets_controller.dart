import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeflow_app/features/finance/data/supabase_budget_repository.dart';
import 'package:lifeflow_app/features/finance/domain/budget.dart';
import 'package:uuid/uuid.dart';

final budgetsControllerProvider =
    AsyncNotifierProvider<BudgetsController, List<Budget>>(
      BudgetsController.new,
    );

final budgetDetailsProvider = FutureProvider.family<Budget, String>(
  (ref, id) => ref.watch(budgetRepositoryProvider).getBudget(id),
);

class BudgetsController extends AsyncNotifier<List<Budget>> {
  final Uuid _uuid = const Uuid();

  @override
  Future<List<Budget>> build() =>
      ref.watch(budgetRepositoryProvider).getBudgets();

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(budgetRepositoryProvider).getBudgets(),
    );
  }

  Future<Budget> create(BudgetDraft draft) async {
    final budget = await ref
        .read(budgetRepositoryProvider)
        .saveBudget(_uuid.v7(), draft);
    state = AsyncData([budget, ...?state.value]);
    return budget;
  }

  Future<Budget> updateBudget(String id, BudgetDraft draft) async {
    final budget = await ref.read(budgetRepositoryProvider).saveBudget(
      id,
      draft,
    );
    state = AsyncData([
      for (final item in state.value ?? const <Budget>[])
        if (item.id == id) budget else item,
    ]);
    ref.invalidate(budgetDetailsProvider(id));
    return budget;
  }

  Future<void> delete(String id) async {
    await ref.read(budgetRepositoryProvider).deleteBudget(id);
    state = AsyncData(
      (state.value ?? const <Budget>[]).where((b) => b.id != id).toList(),
    );
    ref.invalidate(budgetDetailsProvider(id));
  }
}
