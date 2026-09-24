import 'package:lifeflow_app/features/finance/domain/transaction.dart';

class FinanceTotals {
  const FinanceTotals({
    required this.balance,
    required this.monthlyIncome,
    required this.monthlyExpense,
  });
  final double balance, monthlyIncome, monthlyExpense;
}

class CategoryTotal {
  const CategoryTotal({
    required this.categoryId,
    required this.categoryDescription,
    required this.type,
    required this.totalAmount,
    required this.transactionCount,
    this.categoryColor,
  });
  final String categoryId, categoryDescription;
  final String? categoryColor;
  final TransactionType type;
  final double totalAmount;
  final int transactionCount;
}

class PersonTotal {
  const PersonTotal({
    required this.personId,
    required this.personName,
    required this.type,
    required this.totalAmount,
    required this.transactionCount,
  });
  final String personId, personName;
  final TransactionType type;
  final double totalAmount;
  final int transactionCount;
}

class RankedTransaction {
  const RankedTransaction({
    required this.id,
    required this.transactionDate,
    required this.description,
    required this.amount,
    required this.categoryId,
    required this.categoryDescription,
    required this.rank,
  });
  final String id, categoryId, description, categoryDescription;
  final DateTime transactionDate;
  final double amount;
  final int rank;
}

enum BudgetStatus {
  normal('normal'),
  warning('warning'),
  critical('critical');

  const BudgetStatus(this.databaseValue);
  final String databaseValue;
  static BudgetStatus fromDatabase(String value) =>
      values.firstWhere((x) => x.databaseValue == value);
}

class BudgetProgress {
  const BudgetProgress({
    required this.budgetId,
    required this.categoryId,
    required this.categoryDescription,
    required this.year,
    required this.month,
    required this.limitAmount,
    required this.spentAmount,
    required this.status,
    this.percentage,
  });
  final String budgetId, categoryId, categoryDescription;
  final int year, month;
  final double limitAmount, spentAmount;
  final double? percentage;
  final BudgetStatus status;
}

class MonthlyEvolution {
  const MonthlyEvolution({
    required this.month,
    required this.income,
    required this.expense,
  });
  final DateTime month;
  final double income, expense;
}
