import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeflow_app/features/finance/data/supabase_finance_summary_repository.dart';
import 'package:lifeflow_app/features/finance/domain/finance_summary.dart';
import 'package:lifeflow_app/features/finance/domain/finance_summary_repository.dart';
import 'package:lifeflow_app/features/finance/presentation/finance_summary_controller.dart';

void main() {
  test('expõe os totais e o progresso de orçamento do repositório', () async {
    final container = ProviderContainer(
      overrides: [
        financeSummaryRepositoryProvider.overrideWithValue(_Fake()),
      ],
    );
    addTearDown(container.dispose);

    final totals = await container.read(financeTotalsProvider.future);
    expect(totals.balance, 1000);

    final progress = await container.read(budgetProgressProvider.future);
    expect(progress.single.status, BudgetStatus.warning);
  });
}

class _Fake implements FinanceSummaryRepository {
  @override
  Future<FinanceTotals> getTotals() async => const FinanceTotals(
    balance: 1000,
    monthlyIncome: 3000,
    monthlyExpense: 2000,
  );

  @override
  Future<List<CategoryTotal>> getTotalsByCategory() async => const [];

  @override
  Future<List<PersonTotal>> getTotalsByPerson() async => const [];

  @override
  Future<List<RankedTransaction>> getTopExpenses() async => const [];

  @override
  Future<List<RankedTransaction>> getTopIncome() async => const [];

  @override
  Future<List<BudgetProgress>> getBudgetProgress() async => const [
    BudgetProgress(
      budgetId: 'budget-id',
      categoryId: 'category-id',
      categoryDescription: 'Mercado',
      year: 2026,
      month: 9,
      limitAmount: 500,
      spentAmount: 420,
      percentage: 84,
      status: BudgetStatus.warning,
    ),
  ];

  @override
  Future<List<MonthlyEvolution>> getMonthlyEvolution() async => const [];
}
