class SavingsGoal {
  const SavingsGoal({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.createdAt,
    required this.updatedAt,
    this.targetDate,
  });
  final String id, title;
  final double targetAmount;
  final DateTime? targetDate;
  final DateTime createdAt, updatedAt;
}

class SavingsGoalDraft {
  const SavingsGoalDraft({
    required this.title,
    required this.targetAmount,
    this.targetDate,
  });
  final String title;
  final double targetAmount;
  final DateTime? targetDate;
}

class GoalContribution {
  const GoalContribution({
    required this.id,
    required this.goalId,
    required this.amount,
    required this.contributionDate,
    required this.createdAt,
    this.transactionId,
  });
  final String id, goalId;
  final String? transactionId;
  final double amount;
  final DateTime contributionDate, createdAt;
}

class GoalContributionDraft {
  const GoalContributionDraft({
    required this.goalId,
    required this.amount,
    required this.contributionDate,
    this.transactionId,
  });
  final String goalId;
  final String? transactionId;
  final double amount;
  final DateTime contributionDate;
}
