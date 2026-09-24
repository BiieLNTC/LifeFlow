import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeflow_app/core/supabase/supabase_provider.dart';
import 'package:lifeflow_app/core/sync/offline_repository_support.dart';
import 'package:lifeflow_app/core/sync/offline_store.dart';
import 'package:lifeflow_app/features/finance/domain/recurring_transaction.dart';
import 'package:lifeflow_app/features/finance/domain/recurring_transaction_repository.dart';
import 'package:lifeflow_app/features/finance/domain/transaction.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final recurringTransactionRepositoryProvider =
    Provider<RecurringTransactionRepository>((ref) {
      final client = ref.watch(supabaseClientProvider);
      return SupabaseRecurringTransactionRepository(
        client,
        OfflineRepositorySupport(client, ref.watch(offlineStoreProvider)),
      );
    });

class SupabaseRecurringTransactionRepository
    implements RecurringTransactionRepository {
  SupabaseRecurringTransactionRepository(this._client, this._offline);
  final SupabaseClient _client;
  final OfflineRepositorySupport _offline;

  @override
  Future<List<RecurringTransaction>> getRecurringTransactions() =>
      _guard(() async {
        final rows = await _offline.readList(
          entityType: 'recurring_transaction',
          parentId: null,
          remote: () async =>
              (await _client
                      .from('recurring_transactions')
                      .select()
                      .isFilter('deleted_at', null)
                      .order('description'))
                  .cast<Map<String, dynamic>>(),
        );
        final recurring = rows.map(_fromJson).toList();
        recurring.sort((a, b) => a.description.compareTo(b.description));
        return recurring;
      });

  @override
  Future<RecurringTransaction> getRecurringTransaction(String id) => _guard(
    () async => _fromJson(
      await _offline.readOne(
        entityType: 'recurring_transaction',
        recordId: id,
        remote: () => _client
            .from('recurring_transactions')
            .select()
            .eq('id', id)
            .isFilter('deleted_at', null)
            .single(),
      ),
    ),
  );

  @override
  Future<RecurringTransaction> saveRecurringTransaction(
    String id,
    RecurringTransactionDraft draft,
  ) => _guard(() async {
    final payload = {'id': id, ..._draftToJson(draft), 'deleted_at': null};
    final previous = await _offline.store.readRecord(
      userId: _offline.userId,
      entityType: 'recurring_transaction',
      recordId: id,
    );
    final row = await _offline.save(
      entityType: 'recurring_transaction',
      recordId: id,
      parentId: null,
      localRecord: _localJson(id, draft, previous: previous),
      remotePayload: payload,
      remote: () => _client
          .from('recurring_transactions')
          .upsert(payload)
          .select()
          .single(),
    );
    return _fromJson(row);
  });

  @override
  Future<void> deleteRecurringTransaction(String id) => _guard(() async {
    await _offline.delete(
      entityType: 'recurring_transaction',
      recordId: id,
      parentId: null,
      remote: () async {
        await _client
            .from('recurring_transactions')
            .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
            .eq('id', id)
            .select('id')
            .single();
      },
    );
  });

  @override
  Future<int> generateDueOccurrences() => _guard(() async {
    final result = await _client.rpc('generate_due_recurring_transactions');
    return result is num ? result.toInt() : int.parse(result.toString());
  });

  Map<String, Object?> _draftToJson(RecurringTransactionDraft draft) => {
    'category_id': draft.categoryId,
    'person_id': draft.personId,
    'description': draft.description.trim(),
    'type': draft.type.databaseValue,
    'amount': draft.amount,
    'day_of_month': draft.dayOfMonth,
    'start_date': draft.startDate.toIso8601String().split('T').first,
    'end_date': draft.endDate?.toIso8601String().split('T').first,
    'paused': draft.paused,
  };

  Map<String, dynamic> _localJson(
    String id,
    RecurringTransactionDraft draft, {
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

  RecurringTransaction _fromJson(Map<String, dynamic> j) =>
      RecurringTransaction(
        id: j['id'] as String,
        categoryId: j['category_id'] as String,
        personId: j['person_id'] as String?,
        description: j['description'] as String,
        type: TransactionType.fromDatabase(j['type'] as String),
        amount: _number(j['amount']),
        dayOfMonth: j['day_of_month'] as int,
        startDate: DateTime.parse(j['start_date'] as String),
        endDate: j['end_date'] == null
            ? null
            : DateTime.parse(j['end_date'] as String),
        paused: j['paused'] as bool,
        createdAt: DateTime.parse(j['created_at'] as String).toUtc(),
        updatedAt: DateTime.parse(j['updated_at'] as String).toUtc(),
      );

  double _number(Object v) =>
      v is num ? v.toDouble() : double.parse(v as String);

  Future<T> _guard<T>(Future<T> Function() op) async {
    try {
      return await op();
    } on PostgrestException catch (e) {
      throw RecurringTransactionFailure(
        e.code == '42501'
            ? 'Você não tem permissão para esta recorrência.'
            : 'Revise os dados da transação recorrente.',
      );
    } catch (e) {
      if (e is RecurringTransactionFailure) rethrow;
      throw const RecurringTransactionFailure(
        'Não foi possível conectar ao serviço.',
      );
    }
  }
}
