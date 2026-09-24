import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeflow_app/features/finance/data/supabase_finance_summary_repository.dart';
import 'package:lifeflow_app/features/finance/domain/finance_summary.dart';

final financeTotalsProvider = FutureProvider<FinanceTotals>(
  (ref) => ref.watch(financeSummaryRepositoryProvider).getTotals(),
);

final financeTotalsByCategoryProvider = FutureProvider<List<CategoryTotal>>(
  (ref) => ref.watch(financeSummaryRepositoryProvider).getTotalsByCategory(),
);

final financeTotalsByPersonProvider = FutureProvider<List<PersonTotal>>(
  (ref) => ref.watch(financeSummaryRepositoryProvider).getTotalsByPerson(),
);

final financeTopExpensesProvider = FutureProvider<List<RankedTransaction>>(
  (ref) => ref.watch(financeSummaryRepositoryProvider).getTopExpenses(),
);

final financeTopIncomeProvider = FutureProvider<List<RankedTransaction>>(
  (ref) => ref.watch(financeSummaryRepositoryProvider).getTopIncome(),
);

final budgetProgressProvider = FutureProvider<List<BudgetProgress>>(
  (ref) => ref.watch(financeSummaryRepositoryProvider).getBudgetProgress(),
);

final financeMonthlyEvolutionProvider =
    FutureProvider<List<MonthlyEvolution>>(
      (ref) =>
          ref.watch(financeSummaryRepositoryProvider).getMonthlyEvolution(),
    );
