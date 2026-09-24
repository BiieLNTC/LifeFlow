import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeflow_app/core/supabase/supabase_provider.dart';
import 'package:lifeflow_app/core/sync/offline_repository_support.dart';
import 'package:lifeflow_app/core/sync/offline_store.dart';
import 'package:lifeflow_app/features/expenses/domain/expense.dart';
import 'package:lifeflow_app/features/expenses/domain/expense_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseExpenseRepository(
    client,
    OfflineRepositorySupport(client, ref.watch(offlineStoreProvider)),
  );
});

class SupabaseExpenseRepository implements ExpenseRepository {
  SupabaseExpenseRepository(this.client, this.offline);
  final SupabaseClient client;
  final OfflineRepositorySupport offline;
  @override
  Future<List<Expense>> getExpenses(String vehicleId) => _guard(() async {
    final rows = await offline.readList(
      entityType: 'expense',
      parentId: vehicleId,
      remote: () async =>
          (await client
                  .from('expenses')
                  .select()
                  .eq('vehicle_id', vehicleId)
                  .isFilter('deleted_at', null)
                  .order('expense_date', ascending: false)
                  .order('created_at', ascending: false))
              .cast<Map<String, dynamic>>(),
    );
    final result = rows.map(_fromJson).toList();
    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  });
  @override
  Future<Expense> getExpense(String id) => _guard(
    () async => _fromJson(
      await offline.readOne(
        entityType: 'expense',
        recordId: id,
        remote: () => client
            .from('expenses')
            .select()
            .eq('id', id)
            .isFilter('deleted_at', null)
            .single(),
      ),
    ),
  );
  @override
  Future<Expense> saveExpense(String id, ExpenseDraft d) => _guard(() async {
    final payload = {
      'id': id,
      'vehicle_id': d.vehicleId,
      'category': d.category.databaseValue,
      'expense_date': _date(d.date),
      'amount': d.amount,
      'description': d.description.trim(),
      'notes': _text(d.notes),
      'deleted_at': null,
    };
    final previous = await offline.store.readRecord(
      userId: offline.userId,
      entityType: 'expense',
      recordId: id,
    );
    final row = await offline.save(
      entityType: 'expense',
      recordId: id,
      parentId: d.vehicleId,
      localRecord: _localJson(id, d, previous: previous),
      remotePayload: payload,
      remote: () => client.from('expenses').upsert(payload).select().single(),
    );
    return _fromJson(row);
  });
  @override
  Future<void> deleteExpense(String id) => _guard(() async {
    final previous = await offline.store.readRecord(
      userId: offline.userId,
      entityType: 'expense',
      recordId: id,
    );
    await offline.delete(
      entityType: 'expense',
      recordId: id,
      parentId: previous?['vehicle_id'] as String?,
      remote: () async {
        await client
            .from('expenses')
            .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
            .eq('id', id)
            .select('id')
            .single();
      },
    );
  });
  Expense _fromJson(Map<String, dynamic> j) => Expense(
    id: j['id'],
    vehicleId: j['vehicle_id'],
    category: ExpenseCategory.fromDatabase(j['category']),
    date: DateTime.parse(j['expense_date']),
    amount: _number(j['amount']),
    description: j['description'],
    notes: j['notes'],
    createdAt: DateTime.parse(j['created_at']).toUtc(),
    updatedAt: DateTime.parse(j['updated_at']).toUtc(),
  );
  Map<String, dynamic> _localJson(
    String id,
    ExpenseDraft d, {
    Map<String, dynamic>? previous,
  }) {
    final now = DateTime.now().toUtc().toIso8601String();
    return {
      'id': id,
      'vehicle_id': d.vehicleId,
      'category': d.category.databaseValue,
      'expense_date': _date(d.date),
      'amount': d.amount,
      'description': d.description.trim(),
      'notes': _text(d.notes),
      'created_at': previous?['created_at'] ?? now,
      'updated_at': now,
      'deleted_at': null,
    };
  }

  double _number(Object v) =>
      v is num ? v.toDouble() : double.parse(v as String);
  String _date(DateTime d) => d.toIso8601String().split('T').first;
  String? _text(String? v) {
    final x = v?.trim();
    return x == null || x.isEmpty ? null : x;
  }

  Future<T> _guard<T>(Future<T> Function() op) async {
    try {
      return await op();
    } on PostgrestException catch (e) {
      if (e.message.contains('future')) {
        throw const ExpenseFailure(
          'A data da despesa não pode estar no futuro.',
        );
      }
      throw ExpenseFailure(
        e.code == '42501'
            ? 'Você não tem permissão para esta despesa.'
            : 'Revise os dados da despesa.',
      );
    } catch (e) {
      if (e is ExpenseFailure) rethrow;
      throw const ExpenseFailure('Não foi possível conectar ao serviço.');
    }
  }
}
