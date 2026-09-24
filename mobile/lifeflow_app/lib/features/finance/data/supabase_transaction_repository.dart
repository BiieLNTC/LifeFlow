import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeflow_app/core/supabase/supabase_provider.dart';
import 'package:lifeflow_app/core/sync/offline_repository_support.dart';
import 'package:lifeflow_app/core/sync/offline_store.dart';
import 'package:lifeflow_app/features/finance/domain/transaction.dart';
import 'package:lifeflow_app/features/finance/domain/transaction_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseTransactionRepository(
    client,
    OfflineRepositorySupport(client, ref.watch(offlineStoreProvider)),
  );
});

class SupabaseTransactionRepository implements TransactionRepository {
  SupabaseTransactionRepository(this._client, this._offline);
  final SupabaseClient _client;
  final OfflineRepositorySupport _offline;
  final Uuid _uuid = const Uuid();

  @override
  Future<List<Transaction>> getTransactions() => _guard(() async {
    final rows = await _offline.readList(
      entityType: 'transaction',
      parentId: null,
      remote: () async =>
          (await _client
                  .from('transactions')
                  .select()
                  .isFilter('deleted_at', null)
                  .order('transaction_date', ascending: false)
                  .order('created_at', ascending: false))
              .cast<Map<String, dynamic>>(),
    );
    final transactions = rows.map(_fromJson).toList();
    transactions.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    return transactions;
  });

  @override
  Future<Transaction> getTransaction(String id) => _guard(
    () async => _fromJson(
      await _offline.readOne(
        entityType: 'transaction',
        recordId: id,
        remote: () => _client
            .from('transactions')
            .select()
            .eq('id', id)
            .isFilter('deleted_at', null)
            .single(),
      ),
    ),
  );

  @override
  Future<Transaction> saveTransaction(String id, TransactionDraft draft) =>
      _guard(() async {
        final previous = await _offline.store.readRecord(
          userId: _offline.userId,
          entityType: 'transaction',
          recordId: id,
        );
        final payload = {
          'id': id,
          ..._draftToJson(draft),
          'source_type': previous?['source_type'],
          'source_id': previous?['source_id'],
          'installment_group_id': previous?['installment_group_id'],
          'installment_index': previous?['installment_index'],
          'installment_total': previous?['installment_total'],
          'deleted_at': null,
        };
        final row = await _offline.save(
          entityType: 'transaction',
          recordId: id,
          parentId: null,
          localRecord: _localJson(id, draft, previous: previous),
          remotePayload: payload,
          remote: () =>
              _client.from('transactions').upsert(payload).select().single(),
        );
        return _fromJson(row);
      });

  @override
  Future<List<Transaction>> createInstallmentPurchase(
    TransactionDraft draft,
    int installments,
  ) => _guard(() async {
    if (installments < 2) {
      throw const TransactionFailure(
        'Uma compra parcelada precisa de ao menos 2 parcelas.',
      );
    }
    final groupId = _uuid.v7();
    final results = <Transaction>[];
    for (var index = 1; index <= installments; index++) {
      final id = _uuid.v7();
      final installmentDate = DateTime(
        draft.transactionDate.year,
        draft.transactionDate.month + (index - 1),
        draft.transactionDate.day,
      );
      final payload = {
        'id': id,
        ..._draftToJson(
          TransactionDraft(
            categoryId: draft.categoryId,
            personId: draft.personId,
            transactionDate: installmentDate,
            description: draft.description,
            type: draft.type,
            amount: draft.amount,
          ),
        ),
        'installment_group_id': groupId,
        'installment_index': index,
        'installment_total': installments,
      };
      final row = await _offline.save(
        entityType: 'transaction',
        recordId: id,
        parentId: null,
        localRecord: {
          ...payload,
          'user_id': _offline.userId,
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
          'deleted_at': null,
          'source_type': null,
          'source_id': null,
        },
        remotePayload: payload,
        remote: () =>
            _client.from('transactions').insert(payload).select().single(),
      );
      results.add(_fromJson(row));
    }
    return results;
  });

  @override
  Future<void> deleteTransaction(String id) => _guard(() async {
    await _offline.delete(
      entityType: 'transaction',
      recordId: id,
      parentId: null,
      remote: () async {
        await _client
            .from('transactions')
            .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
            .eq('id', id)
            .select('id')
            .single();
      },
    );
  });

  Map<String, Object?> _draftToJson(TransactionDraft draft) => {
    'category_id': draft.categoryId,
    'person_id': draft.personId,
    'transaction_date': draft.transactionDate.toIso8601String().split(
      'T',
    ).first,
    'description': draft.description.trim(),
    'type': draft.type.databaseValue,
    'amount': draft.amount,
  };

  Map<String, dynamic> _localJson(
    String id,
    TransactionDraft draft, {
    Map<String, dynamic>? previous,
  }) {
    final now = DateTime.now().toUtc().toIso8601String();
    return {
      'id': id,
      'user_id': _offline.userId,
      ..._draftToJson(draft),
      'source_type': previous?['source_type'],
      'source_id': previous?['source_id'],
      'installment_group_id': previous?['installment_group_id'],
      'installment_index': previous?['installment_index'],
      'installment_total': previous?['installment_total'],
      'created_at': previous?['created_at'] ?? now,
      'updated_at': now,
      'deleted_at': null,
    };
  }

  Transaction _fromJson(Map<String, dynamic> j) => Transaction(
    id: j['id'] as String,
    categoryId: j['category_id'] as String,
    personId: j['person_id'] as String?,
    transactionDate: DateTime.parse(j['transaction_date'] as String),
    description: j['description'] as String,
    type: TransactionType.fromDatabase(j['type'] as String),
    amount: _number(j['amount']),
    source: j['source_type'] == null
        ? null
        : TransactionSource.fromDatabase(j['source_type'] as String),
    sourceId: j['source_id'] as String?,
    installmentGroupId: j['installment_group_id'] as String?,
    installmentIndex: j['installment_index'] as int?,
    installmentTotal: j['installment_total'] as int?,
    createdAt: DateTime.parse(j['created_at'] as String).toUtc(),
    updatedAt: DateTime.parse(j['updated_at'] as String).toUtc(),
  );

  double _number(Object v) =>
      v is num ? v.toDouble() : double.parse(v as String);

  Future<T> _guard<T>(Future<T> Function() op) async {
    try {
      return await op();
    } on PostgrestException catch (e) {
      throw TransactionFailure(
        e.code == '23505'
            ? 'Esta transação já existe.'
            : e.code == '42501' || e.code == 'PGRST116'
            ? 'Esta transação foi gerada automaticamente e só pode ser alterada pela origem (veículo ou recorrência).'
            : 'Revise os dados da transação.',
      );
    } catch (e) {
      if (e is TransactionFailure) rethrow;
      throw const TransactionFailure('Não foi possível conectar ao serviço.');
    }
  }
}
