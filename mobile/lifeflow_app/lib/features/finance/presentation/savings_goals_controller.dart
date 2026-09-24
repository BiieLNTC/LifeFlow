import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeflow_app/features/finance/data/supabase_savings_goal_repository.dart';
import 'package:lifeflow_app/features/finance/domain/savings_goal.dart';
import 'package:uuid/uuid.dart';

final savingsGoalsControllerProvider =
    AsyncNotifierProvider<SavingsGoalsController, List<SavingsGoal>>(
      SavingsGoalsController.new,
    );

final savingsGoalDetailsProvider = FutureProvider.family<SavingsGoal, String>(
  (ref, id) => ref.watch(savingsGoalRepositoryProvider).getSavingsGoal(id),
);

final goalContributionsProvider =
    AsyncNotifierProvider.family<
      GoalContributionsController,
      List<GoalContribution>,
      String
    >(GoalContributionsController.new);

class SavingsGoalsController extends AsyncNotifier<List<SavingsGoal>> {
  final Uuid _uuid = const Uuid();

  @override
  Future<List<SavingsGoal>> build() =>
      ref.watch(savingsGoalRepositoryProvider).getSavingsGoals();

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(savingsGoalRepositoryProvider).getSavingsGoals(),
    );
  }

  Future<SavingsGoal> create(SavingsGoalDraft draft) async {
    final goal = await ref
        .read(savingsGoalRepositoryProvider)
        .saveSavingsGoal(_uuid.v7(), draft);
    state = AsyncData([goal, ...?state.value]);
    return goal;
  }

  Future<SavingsGoal> updateSavingsGoal(String id, SavingsGoalDraft draft) async {
    final goal = await ref
        .read(savingsGoalRepositoryProvider)
        .saveSavingsGoal(id, draft);
    state = AsyncData([
      for (final item in state.value ?? const <SavingsGoal>[])
        if (item.id == id) goal else item,
    ]);
    ref.invalidate(savingsGoalDetailsProvider(id));
    return goal;
  }

  Future<void> delete(String id) async {
    await ref.read(savingsGoalRepositoryProvider).deleteSavingsGoal(id);
    state = AsyncData(
      (state.value ?? const <SavingsGoal>[]).where((g) => g.id != id).toList(),
    );
    ref.invalidate(savingsGoalDetailsProvider(id));
  }
}

class GoalContributionsController
    extends AsyncNotifier<List<GoalContribution>> {
  GoalContributionsController(this.goalId);
  final String goalId;

  @override
  Future<List<GoalContribution>> build() =>
      ref.watch(savingsGoalRepositoryProvider).getContributions(goalId);

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(savingsGoalRepositoryProvider).getContributions(goalId),
    );
  }

  Future<GoalContribution> add(GoalContributionDraft draft) async {
    final contribution = await ref
        .read(savingsGoalRepositoryProvider)
        .addContribution(draft);
    state = AsyncData([contribution, ...?state.value]);
    return contribution;
  }

  Future<void> delete(String id) async {
    await ref
        .read(savingsGoalRepositoryProvider)
        .deleteContribution(id, goalId: goalId);
    state = AsyncData(
      (state.value ?? const <GoalContribution>[])
          .where((c) => c.id != id)
          .toList(),
    );
  }
}
