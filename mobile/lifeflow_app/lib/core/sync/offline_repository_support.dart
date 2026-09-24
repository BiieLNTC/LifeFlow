import 'package:lifeflow_app/core/sync/network_failure.dart';
import 'package:lifeflow_app/core/sync/offline_store.dart';
import 'package:lifeflow_app/core/sync/sync_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OfflineRepositorySupport {
  OfflineRepositorySupport(this.client, this.store);
  final SupabaseClient client;
  final OfflineStore store;

  String get userId {
    final id = client.auth.currentUser?.id;
    if (id == null) throw StateError('Sessão indisponível para cache local.');
    return id;
  }

  Future<List<Map<String, dynamic>>> readList({
    required String entityType,
    required String? parentId,
    required Future<List<Map<String, dynamic>>> Function() remote,
    int cachedOffset = 0,
    int? cachedLimit,
    int Function(Map<String, dynamic>, Map<String, dynamic>)? sortCached,
    bool replaceCached = true,
    String parentIdField = 'vehicle_id',
  }) async {
    try {
      final rows = await remote();
      await store.cacheRecords(
        userId: userId,
        entityType: entityType,
        records: rows,
        parentId: entityType == 'vehicle'
            ? (_) => null
            : (record) => record[parentIdField] as String?,
        replaceSynced: replaceCached,
        scopeParentId: parentId,
      );
      return await _mergePending(rows, entityType, parentId);
    } catch (error) {
      try {
        throwOfflineOrRethrow(error);
      } on OfflineUnavailable {
        final cached = await store.readRecords(
          userId: userId,
          entityType: entityType,
          parentId: parentId,
        );
        if (sortCached != null) cached.sort(sortCached);
        return cached
            .skip(cachedOffset)
            .take(cachedLimit ?? cached.length)
            .toList(growable: false);
      }
    }
  }

  Future<Map<String, dynamic>> readOne({
    required String entityType,
    required String recordId,
    required Future<Map<String, dynamic>> Function() remote,
  }) async {
    try {
      final row = await remote();
      await store.cacheRecords(
        userId: userId,
        entityType: entityType,
        records: [row],
        parentId: entityType == 'vehicle'
            ? (_) => null
            : (record) => record['vehicle_id'] as String?,
      );
      return await store.readRecord(
            userId: userId,
            entityType: entityType,
            recordId: recordId,
          ) ??
          row;
    } catch (error) {
      try {
        throwOfflineOrRethrow(error);
      } on OfflineUnavailable {
        final cached = await store.readRecord(
          userId: userId,
          entityType: entityType,
          recordId: recordId,
        );
        if (cached != null) return cached;
        rethrow;
      }
    }
  }

  Future<Map<String, dynamic>> save({
    required String entityType,
    required String recordId,
    required String? parentId,
    required Map<String, dynamic> localRecord,
    required Map<String, dynamic> remotePayload,
    required Future<Map<String, dynamic>> Function() remote,
    SyncOperation? operation,
  }) async {
    final existing = await store.readRecord(
      userId: userId,
      entityType: entityType,
      recordId: recordId,
    );
    final effectiveOperation =
        operation ??
        (existing == null ? SyncOperation.create : SyncOperation.update);
    if (await store.hasUnsyncedRecord(
      userId: userId,
      entityType: entityType,
      recordId: recordId,
    )) {
      await store.savePending(
        userId: userId,
        entityType: entityType,
        recordId: recordId,
        parentId: parentId,
        localRecord: localRecord,
        remotePayload: remotePayload,
        operation: effectiveOperation,
        baseUpdatedAt: _updatedAt(existing),
      );
      return localRecord;
    }
    try {
      final row = await remote();
      await store.cacheRecords(
        userId: userId,
        entityType: entityType,
        records: [row],
        parentId: (_) => parentId,
      );
      return row;
    } catch (error) {
      try {
        throwOfflineOrRethrow(error);
      } on OfflineUnavailable {
        await store.savePending(
          userId: userId,
          entityType: entityType,
          recordId: recordId,
          parentId: parentId,
          localRecord: localRecord,
          remotePayload: remotePayload,
          operation: effectiveOperation,
          baseUpdatedAt: _updatedAt(existing),
        );
        return localRecord;
      }
    }
  }

  Future<void> delete({
    required String entityType,
    required String recordId,
    required String? parentId,
    required Future<void> Function() remote,
  }) async {
    final existing = await store.readRecord(
      userId: userId,
      entityType: entityType,
      recordId: recordId,
    );
    if (await store.hasUnsyncedRecord(
      userId: userId,
      entityType: entityType,
      recordId: recordId,
    )) {
      await store.markPendingDelete(
        userId: userId,
        entityType: entityType,
        recordId: recordId,
        parentId: parentId,
        remotePayload: const {},
        baseUpdatedAt: _updatedAt(existing),
      );
      return;
    }
    try {
      await remote();
      await store.removeRecord(
        userId: userId,
        entityType: entityType,
        recordId: recordId,
      );
    } catch (error) {
      try {
        throwOfflineOrRethrow(error);
      } on OfflineUnavailable {
        await store.markPendingDelete(
          userId: userId,
          entityType: entityType,
          recordId: recordId,
          parentId: parentId,
          remotePayload: const {},
          baseUpdatedAt: _updatedAt(existing),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _mergePending(
    List<Map<String, dynamic>> remote,
    String entityType,
    String? parentId,
  ) async {
    final local = await store.readUnsyncedRecords(
      userId: userId,
      entityType: entityType,
      parentId: parentId,
    );
    final byId = {for (final row in remote) row['id'] as String: row};
    for (final row in local) {
      byId[row['id'] as String] = row;
    }
    return byId.values.toList(growable: false);
  }

  DateTime? _updatedAt(Map<String, dynamic>? record) {
    final value = record?['updated_at'];
    return value == null ? null : DateTime.parse(value as String).toUtc();
  }
}
