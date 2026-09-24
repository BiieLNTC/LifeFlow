import 'package:lifeflow_app/features/finance/domain/savings_goal.dart';

class SavingsGoalFailure implements Exception {
  const SavingsGoalFailure(this.message);
  final String message;
}

abstract interface class SavingsGoalRepository {
  Future<List<SavingsGoal>> getSavingsGoals();
  Future<SavingsGoal> getSavingsGoal(String id);
  Future<SavingsGoal> saveSavingsGoal(String id, SavingsGoalDraft draft);
  Future<void> deleteSavingsGoal(String id);

  Future<List<GoalContribution>> getContributions(String goalId);
  Future<GoalContribution> addContribution(GoalContributionDraft draft);
  Future<void> deleteContribution(String id, {required String goalId});
}
