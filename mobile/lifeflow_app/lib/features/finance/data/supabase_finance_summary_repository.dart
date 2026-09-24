import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeflow_app/core/supabase/supabase_provider.dart';
import 'package:lifeflow_app/core/sync/offline_repository_support.dart';
import 'package:lifeflow_app/core/sync/offline_store.dart';
import 'package:lifeflow_app/features/finance/domain/finance_summary.dart';
import 'package:lifeflow_app/features/finance/domain/finance_summary_repository.dart';
import 'package:lifeflow_app/features/finance/domain/transaction.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final financeSummaryRepositoryProvider = Provider<FinanceSummaryRepository>((
  ref,
) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseFinanceSummaryRepository(
    client,
    OfflineRepositorySupport(client, ref.watch(offlineStoreProvider)),
  );
});

class SupabaseFinanceSummaryRepository implements FinanceSummaryRepository {
  SupabaseFinanceSummaryRepository(this._client, this._offline);
  final SupabaseClient _client;
  final OfflineRepositorySupport _offline;

  @override
  Future<FinanceTotals> getTotals() => _guard(() async {
    final rows = await _offline.readList(
      entityType: 'finance_totals',
      parentId: null,
      remote: () async {
        final row = await _client.from('finance_totals').select().single();
        return [<String, dynamic>{'id': 'totals', ...row}];
      },
    );
    final row = rows.single;
    return FinanceTotals(
      balance: _number(row['balance']),
      monthlyIncome: _number(row['monthly_income']),
      monthlyExpense: _number(row['monthly_expense']),
    );
  });

  @override
  Future<List<CategoryTotal>> getTotalsByCategory() => _guard(() async {
    final rows = await _offline.readList(
      entityType: 'finance_totals_by_category',
      parentId: null,
      remote: () async {
        final remote = await _client
            .from('finance_totals_by_category')
            .select();
        return [
          for (final row in remote)
            <String, dynamic>{
              'id': '${row['category_id']}:${row['type']}',
              ...row,
            },
        ];
      },
    );
    return rows
        .map(
          (j) => CategoryTotal(
            categoryId: j['category_id'] as String,
            categoryDescription: j['category_description'] as String,
            categoryColor: j['category_color'] as String?,
            type: TransactionType.fromDatabase(j['type'] as String),
            totalAmount: _number(j['total_amount']),
            transactionCount: j['transaction_count'] as int,
          ),
        )
        .toList(growable: false);
  });

  @override
  Future<List<PersonTotal>> getTotalsByPerson() => _guard(() async {
    final rows = await _offline.readList(
      entityType: 'finance_totals_by_person',
      parentId: null,
      remote: () async {
        final remote = await _client.from('finance_totals_by_person').select();
        return [
          for (final row in remote)
            <String, dynamic>{'id': '${row['person_id']}:${row['type']}', ...row},
        ];
      },
    );
    return rows
        .map(
          (j) => PersonTotal(
            personId: j['person_id'] as String,
            personName: j['person_name'] as String,
            type: TransactionType.fromDatabase(j['type'] as String),
            totalAmount: _number(j['total_amount']),
            transactionCount: j['transaction_count'] as int,
          ),
        )
        .toList(growable: false);
  });

  @override
  Future<List<RankedTransaction>> getTopExpenses() =>
      _rankedTransactions('finance_top_expenses');

  @override
  Future<List<RankedTransaction>> getTopIncome() =>
      _rankedTransactions('finance_top_income');

  Future<List<RankedTransaction>> _rankedTransactions(String view) =>
      _guard(() async {
        final rows = await _offline.readList(
          entityType: view,
          parentId: null,
          remote: () async =>
              (await _client.from(view).select()).cast<Map<String, dynamic>>(),
          sortCached: (a, b) => (a['rank'] as int).compareTo(b['rank'] as int),
        );
        final result = rows
            .map(
              (j) => RankedTransaction(
                id: j['id'] as String,
                transactionDate: DateTime.parse(
                  j['transaction_date'] as String,
                ),
                description: j['description'] as String,
                amount: _number(j['amount']),
                categoryId: j['category_id'] as String,
                categoryDescription: j['category_description'] as String,
                rank: j['rank'] as int,
              ),
            )
            .toList();
        result.sort((a, b) => a.rank.compareTo(b.rank));
        return result;
      });

  @override
  Future<List<BudgetProgress>> getBudgetProgress() => _guard(() async {
    final rows = await _offline.readList(
      entityType: 'budget_progress',
      parentId: null,
      remote: () async {
        final remote = await _client.from('budget_progress').select();
        return [
          for (final row in remote)
            <String, dynamic>{'id': row['budget_id'], ...row},
        ];
      },
    );
    return rows
        .map(
          (j) => BudgetProgress(
            budgetId: j['budget_id'] as String,
            categoryId: j['category_id'] as String,
            categoryDescription: j['category_description'] as String,
            year: j['year'] as int,
            month: j['month'] as int,
            limitAmount: _number(j['limit_amount']),
            spentAmount: _number(j['spent_amount']),
            percentage: j['percentage'] == null
                ? null
                : _number(j['percentage']),
            status: BudgetStatus.fromDatabase(j['status'] as String),
          ),
        )
        .toList(growable: false);
  });

  @override
  Future<List<MonthlyEvolution>> getMonthlyEvolution() => _guard(() async {
    final rows = await _offline.readList(
      entityType: 'finance_monthly_evolution',
      parentId: null,
      remote: () async {
        final remote = await _client.from('finance_monthly_evolution').select();
        return [
          for (final row in remote) <String, dynamic>{'id': row['month'], ...row},
        ];
      },
      sortCached: (a, b) =>
          (a['month'] as String).compareTo(b['month'] as String),
    );
    final result = rows
        .map(
          (j) => MonthlyEvolution(
            month: DateTime.parse(j['month'] as String),
            income: _number(j['income']),
            expense: _number(j['expense']),
          ),
        )
        .toList();
    result.sort((a, b) => a.month.compareTo(b.month));
    return result;
  });

  double _number(Object v) =>
      v is num ? v.toDouble() : double.parse(v as String);

  Future<T> _guard<T>(Future<T> Function() op) async {
    try {
      return await op();
    } on PostgrestException catch (_) {
      throw const FinanceSummaryFailure(
        'Não foi possível carregar o resumo financeiro.',
      );
    } catch (e) {
      if (e is FinanceSummaryFailure) rethrow;
      throw const FinanceSummaryFailure(
        'Não foi possível conectar ao serviço.',
      );
    }
  }
}
