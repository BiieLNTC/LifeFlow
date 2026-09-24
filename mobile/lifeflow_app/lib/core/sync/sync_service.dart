import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeflow_app/core/database/app_database.dart';
import 'package:lifeflow_app/core/supabase/supabase_provider.dart';
import 'package:lifeflow_app/core/sync/network_failure.dart';
import 'package:lifeflow_app/core/sync/offline_store.dart';
import 'package:lifeflow_app/core/sync/sync_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SyncService {
  SyncService(this.client, this.store);
  final SupabaseClient client;
  final OfflineStore store;
  bool _running = false;

  Future<void> sync({bool retryFailed = false}) async {
    if (_running) return;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;
    _running = true;
    try {
      if (retryFailed) await store.retryFailed(userId);
      final mutations = await store.pendingForUser(userId);
      for (final mutation in mutations) {
        try {
          await _syncOne(mutation);
        } on OfflineUnavailable {
          break;
        } on SyncConflict catch (conflict) {
          await store.markFailed(mutation, conflict.message);
        } on PostgrestException catch (error) {
          await store.markFailed(
            mutation,
            error.code == '42501'
                ? 'Permissão negada pelo servidor.'
                : 'O servidor rejeitou os dados pendentes.',
          );
        } catch (error) {
          try {
            throwOfflineOrRethrow(error);
          } on OfflineUnavailable {
            break;
          } catch (_) {
            await store.markFailed(
              mutation,
              'Não foi possível sincronizar este registro.',
            );
          }
        }
      }
    } finally {
      _running = false;
    }
  }

  Future<void> _syncOne(PendingMutation mutation) async {
    final operation = SyncOperation.fromDatabase(mutation.operation);
    final payload = jsonDecode(mutation.payloadJson) as Map<String, dynamic>;
    await _checkConflict(mutation, operation);

    if (operation == SyncOperation.delete) {
      if (mutation.entityType == 'goal_contribution') {
        await client
            .from(_tableFor(mutation.entityType))
            .delete()
            .eq('id', mutation.recordId);
      } else {
        await client
            .from(_tableFor(mutation.entityType))
            .update({
              'deleted_at': DateTime.now().toUtc().toIso8601String(),
              if (mutation.entityType == 'vehicle') 'active': false,
            })
            .eq('id', mutation.recordId)
            .select('id')
            .single();
      }
      await store.markSynced(mutation);
      return;
    }

    if (mutation.entityType == 'maintenance') {
      await client.rpc('save_maintenance', params: payload);
    } else {
      await client.from(_tableFor(mutation.entityType)).upsert(payload);
    }
    await store.markSynced(mutation);
    final remote = await _fetchRemote(mutation.entityType, mutation.recordId);
    await store.cacheRecords(
      userId: mutation.userId,
      entityType: mutation.entityType,
      records: [remote],
      parentId: _parentIdFor(mutation.entityType),
    );
  }

  Future<void> _checkConflict(
    PendingMutation mutation,
    SyncOperation operation,
  ) async {
    final base = mutation.baseUpdatedAt;
    if (base == null || operation == SyncOperation.create) return;
    final row = await client
        .from(_tableFor(mutation.entityType))
        .select('updated_at')
        .eq('id', mutation.recordId)
        .maybeSingle();
    if (row == null) {
      throw const SyncConflict(
        'O registro foi removido no servidor. Seus dados locais foram preservados.',
      );
    }
    final remote = DateTime.parse(row['updated_at']).toUtc();
    if (!remote.isAtSameMomentAs(base.toUtc())) {
      throw const SyncConflict(
        'Este registro mudou em outro dispositivo. Seus dados locais foram preservados para revisão.',
      );
    }
  }

  Future<Map<String, dynamic>> _fetchRemote(
    String entityType,
    String id,
  ) async {
    final source = switch (entityType) {
      'maintenance' => 'maintenances',
      'refueling' => 'refueling_details',
      'reminder' => 'reminder_details',
      _ => _tableFor(entityType),
    };
    final selection = entityType == 'maintenance'
        ? '*, maintenance_items(*)'
        : '*';
    return client.from(source).select(selection).eq('id', id).single();
  }

  String _tableFor(String entityType) => switch (entityType) {
    'vehicle' => 'vehicles',
    'maintenance' => 'maintenances',
    'refueling' => 'refuelings',
    'expense' => 'expenses',
    'reminder' => 'reminders',
    'category' => 'categories',
    'person' => 'people',
    'transaction' => 'transactions',
    'budget' => 'budgets',
    'recurring_transaction' => 'recurring_transactions',
    'savings_goal' => 'savings_goals',
    'goal_contribution' => 'goal_contributions',
    _ => throw StateError('Entidade offline desconhecida: $entityType'),
  };

  static const _topLevelEntityTypes = {
    'vehicle',
    'category',
    'person',
    'transaction',
    'budget',
    'recurring_transaction',
    'savings_goal',
  };

  String? Function(Map<String, dynamic>) _parentIdFor(String entityType) {
    if (_topLevelEntityTypes.contains(entityType)) return (_) => null;
    if (entityType == 'goal_contribution') {
      return (record) => record['goal_id'] as String?;
    }
    return (record) => record['vehicle_id'] as String?;
  }
}

final syncServiceProvider = Provider<SyncService>(
  (ref) => SyncService(
    ref.watch(supabaseClientProvider),
    ref.watch(offlineStoreProvider),
  ),
);

typedef SyncRunner = Future<void> Function({bool retryFailed});

final syncRunnerProvider = Provider<SyncRunner>((ref) {
  return ({bool retryFailed = false}) =>
      ref.read(syncServiceProvider).sync(retryFailed: retryFailed);
});

final syncSummaryProvider = StreamProvider<SyncSummary>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) {
    return Stream.value(const SyncSummary(pending: 0, failed: 0));
  }
  return ref.watch(offlineStoreProvider).watchForUser(userId).map((rows) {
    return SyncSummary(
      pending: rows.where((row) => row.status == 'pending').length,
      failed: rows.where((row) => row.status == 'failed').length,
    );
  });
});
