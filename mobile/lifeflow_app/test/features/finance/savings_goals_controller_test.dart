import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeflow_app/features/finance/data/supabase_savings_goal_repository.dart';
import 'package:lifeflow_app/features/finance/domain/savings_goal.dart';
import 'package:lifeflow_app/features/finance/domain/savings_goal_repository.dart';
import 'package:lifeflow_app/features/finance/presentation/savings_goals_controller.dart';

void main() {
  test('cria, edita e remove meta de poupança', () async {
    final container = ProviderContainer(
      overrides: [savingsGoalRepositoryProvider.overrideWithValue(_Fake())],
    );
    addTearDown(container.dispose);
    await container.read(savingsGoalsControllerProvider.future);
    final controller = container.read(savingsGoalsControllerProvider.notifier);

    final created = await controller.create(_draft(1000));
    expect(created.targetAmount, 1000);

    await controller.updateSavingsGoal(created.id, _draft(1500));
    expect(
      container.read(savingsGoalsControllerProvider).value?.single.targetAmount,
      1500,
    );

    await controller.delete(created.id);
    expect(container.read(savingsGoalsControllerProvider).value, isEmpty);
  });

  test('adiciona e remove aporte de meta', () async {
    final container = ProviderContainer(
      overrides: [savingsGoalRepositoryProvider.overrideWithValue(_Fake())],
    );
    addTearDown(container.dispose);
    const goalId = 'goal-id';
    await container.read(goalContributionsProvider(goalId).future);
    final controller = container.read(
      goalContributionsProvider(goalId).notifier,
    );

    final contribution = await controller.add(
      GoalContributionDraft(
        goalId: goalId,
        amount: 200,
        contributionDate: DateTime.utc(2026, 9, 20),
      ),
    );
    expect(
      container.read(goalContributionsProvider(goalId)).value?.single.amount,
      200,
    );

    await controller.delete(contribution.id);
    expect(container.read(goalContributionsProvider(goalId)).value, isEmpty);
  });
}

SavingsGoalDraft _draft(double targetAmount) =>
    SavingsGoalDraft(title: 'Viagem', targetAmount: targetAmount);

class _Fake implements SavingsGoalRepository {
  SavingsGoal? value;
  final Map<String, GoalContribution> _contributions = {};
  int _contributionCounter = 0;

  @override
  Future<List<SavingsGoal>> getSavingsGoals() async =>
      value == null ? [] : [value!];

  @override
  Future<SavingsGoal> getSavingsGoal(String id) async => value!;

  @override
  Future<SavingsGoal> saveSavingsGoal(String id, SavingsGoalDraft draft) async =>
      value = SavingsGoal(
        id: id,
        title: draft.title,
        targetAmount: draft.targetAmount,
        targetDate: draft.targetDate,
        createdAt: DateTime.utc(2026, 9, 20),
        updatedAt: DateTime.utc(2026, 9, 20),
      );

  @override
  Future<void> deleteSavingsGoal(String id) async => value = null;

  @override
  Future<List<GoalContribution>> getContributions(String goalId) async =>
      _contributions.values.where((c) => c.goalId == goalId).toList();

  @override
  Future<GoalContribution> addContribution(GoalContributionDraft draft) async {
    final id = 'contribution-${_contributionCounter++}';
    final contribution = GoalContribution(
      id: id,
      goalId: draft.goalId,
      transactionId: draft.transactionId,
      amount: draft.amount,
      contributionDate: draft.contributionDate,
      createdAt: DateTime.utc(2026, 9, 20),
    );
    _contributions[id] = contribution;
    return contribution;
  }

  @override
  Future<void> deleteContribution(String id, {required String goalId}) async =>
      _contributions.remove(id);
}
