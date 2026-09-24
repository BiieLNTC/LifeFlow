import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeflow_app/core/supabase/supabase_provider.dart';
import 'package:lifeflow_app/core/sync/offline_repository_support.dart';
import 'package:lifeflow_app/core/sync/offline_store.dart';
import 'package:lifeflow_app/features/finance/domain/budget.dart';
import 'package:lifeflow_app/features/finance/domain/budget_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseBudgetRepository(
    client,
    OfflineRepositorySupport(client, ref.watch(offlineStoreProvider)),
  );
});

class SupabaseBudgetRepository implements BudgetRepository {
  SupabaseBudgetRepository(this._client, this._offline);
  final SupabaseClient _client;
  final OfflineRepositorySupport _offline;

  @override
  Future<List<Budget>> getBudgets() => _guard(() async {
    final rows = await _offline.readList(
      entityType: 'budget',
      parentId: null,
      remote: () async =>
          (await _client
                  .from('budgets')
                  .select()
                  .isFilter('deleted_at', null)
                  .order('year', ascending: false)
                  .order('month', ascending: false))
              .cast<Map<String, dynamic>>(),
    );
    final budgets = rows.map(_fromJson).toList();
    budgets.sort((a, b) {
      final year = b.year.compareTo(a.year);
      return year != 0 ? year : b.month.compareTo(a.month);
    });
    return budgets;
  });

  @override
  Future<Budget> getBudget(String id) => _guard(
    () async => _fromJson(
      await _offline.readOne(
        entityType: 'budget',
        recordId: id,
        remote: () => _client
            .from('budgets')
            .select()
            .eq('id', id)
            .isFilter('deleted_at', null)
            .single(),
      ),
    ),
  );

  @override
  Future<Budget> saveBudget(String id, BudgetDraft draft) => _guard(() async {
    final payload = {'id': id, ..._draftToJson(draft), 'deleted_at': null};
    final previous = await _offline.store.readRecord(
      userId: _offline.userId,
      entityType: 'budget',
      recordId: id,
    );
    final row = await _offline.save(
      entityType: 'budget',
      recordId: id,
      parentId: null,
      localRecord: _localJson(id, draft, previous: previous),
      remotePayload: payload,
      remote: () => _client.from('budgets').upsert(payload).select().single(),
    );
    return _fromJson(row);
  });

  @override
  Future<void> deleteBudget(String id) => _guard(() async {
    await _offline.delete(
      entityType: 'budget',
      recordId: id,
      parentId: null,
      remote: () async {
        await _client
            .from('budgets')
            .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
            .eq('id', id)
            .select('id')
            .single();
      },
    );
  });

  Map<String, Object?> _draftToJson(BudgetDraft draft) => {
    'category_id': draft.categoryId,
    'year': draft.year,
    'month': draft.month,
    'limit_amount': draft.limitAmount,
  };

  Map<String, dynamic> _localJson(
    String id,
    BudgetDraft draft, {
    Map<String, dynamic>? previous,
  }) {
    final now = DateTime.now().toUtc().toIso8601String();
    return {
      'id': id,
      'user_id': _offline.userId,
      ..._draftToJson(draft),
      'created_at': previous?['created_at'] ?? now,
      'updated_at': now,
      'deleted_at': null,
    };
  }

  Budget _fromJson(Map<String, dynamic> j) => Budget(
    id: j['id'] as String,
    categoryId: j['category_id'] as String,
    year: j['year'] as int,
    month: j['month'] as int,
    limitAmount: _number(j['limit_amount']),
    createdAt: DateTime.parse(j['created_at'] as String).toUtc(),
    updatedAt: DateTime.parse(j['updated_at'] as String).toUtc(),
  );

  double _number(Object v) =>
      v is num ? v.toDouble() : double.parse(v as String);

  Future<T> _guard<T>(Future<T> Function() op) async {
    try {
      return await op();
    } on PostgrestException catch (e) {
      throw BudgetFailure(
        e.code == '23505'
            ? 'Já existe um orçamento para esta categoria neste mês.'
            : e.code == '42501'
            ? 'Você não tem permissão para este orçamento.'
            : 'Revise os dados do orçamento.',
      );
    } catch (e) {
      if (e is BudgetFailure) rethrow;
      throw const BudgetFailure('Não foi possível conectar ao serviço.');
    }
  }
}
