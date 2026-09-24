import 'package:lifeflow_app/features/finance/domain/finance_summary.dart';

class FinanceSummaryFailure implements Exception {
  const FinanceSummaryFailure(this.message);
  final String message;
}

abstract interface class FinanceSummaryRepository {
  Future<FinanceTotals> getTotals();
  Future<List<CategoryTotal>> getTotalsByCategory();
  Future<List<PersonTotal>> getTotalsByPerson();
  Future<List<RankedTransaction>> getTopExpenses();
  Future<List<RankedTransaction>> getTopIncome();
  Future<List<BudgetProgress>> getBudgetProgress();
  Future<List<MonthlyEvolution>> getMonthlyEvolution();
}
