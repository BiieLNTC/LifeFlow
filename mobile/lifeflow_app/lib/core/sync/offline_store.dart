import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeflow_app/core/database/app_database.dart';
import 'package:lifeflow_app/core/sync/sync_models.dart';

class OfflineStore {
  OfflineStore(this.database);
  final AppDatabase database;

  Future<void> cacheRecords({
    required String userId,
    required String entityType,
    required Iterable<Map<String, dynamic>> records,
    String? Function(Map<String, dynamic>)? parentId,
    bool replaceSynced = false,
    String? scopeParentId,
  }) async {
    final now = DateTime.now().toUtc();
    await database.transaction(() async {
      if (replaceSynced) {
        final stale = database.delete(database.cachedRecords)
          ..where(
            (row) =>
                row.userId.equals(userId) &
                row.entityType.equals(entityType) &
                row.syncStatus.equals(LocalSyncStatus.synced.databaseValue),
          );
        if (scopeParentId != null) {
          stale.where((row) => row.parentId.equals(scopeParentId));
        } else if (entityType != 'vehicle' && entityType != 'dashboard') {
          stale.where((row) => row.parentId.isNull());
        }
        await stale.go();
      }
      for (final record in records) {
        final id = record['id'] as String;
        final existing = await _record(userId, entityType, id);
        if (existing != null && existing.syncStatus != 'synced') continue;
        await database
            .into(database.cachedRecords)
            .insertOnConflictUpdate(
              CachedRecordsCompanion.insert(
                userId: userId,
                entityType: entityType,
                recordId: id,
                parentId: Value(parentId?.call(record)),
                payloadJson: jsonEncode(record),
                syncStatus: LocalSyncStatus.synced.databaseValue,
                cachedAt: now,
              ),
            );
      }
    });
  }

  Future<List<Map<String, dynamic>>> readRecords({
    required String userId,
    required String entityType,
    String? parentId,
  }) async {
    var query = database.select(database.cachedRecords)
      ..where(
        (row) => row.userId.equals(userId) & row.entityType.equals(entityType),
      );
    if (parentId != null) {
      query = query..where((row) => row.parentId.equals(parentId));
    }
    final rows = await query.get();
    return [
      for (final row in rows)
        if (row.syncStatus != LocalSyncStatus.pendingDelete.databaseValue)
          jsonDecode(row.payloadJson) as Map<String, dynamic>,
    ];
  }

  Future<Map<String, dynamic>?> readRecord({
    required String userId,
    required String entityType,
    required String recordId,
  }) async {
    final row = await _record(userId, entityType, recordId);
    if (row == null ||
        row.syncStatus == LocalSyncStatus.pendingDelete.databaseValue) {
      return null;
    }
    return jsonDecode(row.payloadJson) as Map<String, dynamic>;
  }

  Future<bool> hasUnsyncedRecord({
    required String userId,
    required String entityType,
    required String recordId,
  }) async {
    final row = await _record(userId, entityType, recordId);
    return row != null &&
        row.syncStatus != LocalSyncStatus.synced.databaseValue;
  }

  Future<void> advanceVehicleOdometer({
    required String userId,
    required String vehicleId,
    required int odometer,
  }) async {
    final vehicle = await _record(userId, 'vehicle', vehicleId);
    if (vehicle == null) return;
    final local = jsonDecode(vehicle.payloadJson) as Map<String, dynamic>;
    final current = local['current_odometer'] as int? ?? 0;
    if (odometer <= current) return;

    local['current_odometer'] = odometer;
    final dashboard = await _record(userId, 'dashboard', vehicleId);
    final dashboardPayload = dashboard == null
        ? null
        : jsonDecode(dashboard.payloadJson) as Map<String, dynamic>;
    if (dashboardPayload != null) {
      dashboardPayload['current_odometer'] = odometer;
      final target = dashboardPayload['next_reminder_odometer'] as int?;
      if (target != null) {
        final remaining = target - odometer;
        dashboardPayload['next_reminder_remaining_km'] = remaining;
        dashboardPayload['next_reminder_status'] = remaining <= 0
            ? 'overdue'
            : remaining <= 1000
            ? 'near'
            : 'upcoming';
      }
    }
    final mutation = await _mutation(userId, 'vehicle', vehicleId);
    await database.transaction(() async {
      await (database.update(database.cachedRecords)..where(
            (row) =>
                row.userId.equals(userId) &
                row.entityType.equals('vehicle') &
                row.recordId.equals(vehicleId),
          ))
          .write(
            CachedRecordsCompanion(
              payloadJson: Value(jsonEncode(local)),
              cachedAt: Value(DateTime.now().toUtc()),
            ),
          );

      if (dashboardPayload != null) {
        await (database.update(database.cachedRecords)..where(
              (row) =>
                  row.userId.equals(userId) &
                  row.entityType.equals('dashboard') &
                  row.recordId.equals(vehicleId),
            ))
            .write(
              CachedRecordsCompanion(
                payloadJson: Value(jsonEncode(dashboardPayload)),
                cachedAt: Value(DateTime.now().toUtc()),
              ),
            );
      }

      if (mutation != null) {
        final payload =
            jsonDecode(mutation.payloadJson) as Map<String, dynamic>;
        payload['current_odometer'] = odometer;
        await (database.update(
          database.pendingMutations,
        )..where((row) => row.mutationId.equals(mutation.mutationId))).write(
          PendingMutationsCompanion(
            payloadJson: Value(jsonEncode(payload)),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
      }
    });
  }

  Future<List<Map<String, dynamic>>> readUnsyncedRecords({
    required String userId,
    required String entityType,
    String? parentId,
  }) async {
    var query = database.select(database.cachedRecords)
      ..where(
        (row) =>
            row.userId.equals(userId) &
            row.entityType.equals(entityType) &
            row.syncStatus.equals(LocalSyncStatus.synced.databaseValue).not() &
            row.syncStatus
                .equals(LocalSyncStatus.pendingDelete.databaseValue)
                .not(),
      );
    if (parentId != null) {
      query = query..where((row) => row.parentId.equals(parentId));
    }
    final rows = await query.get();
    return [
      for (final row in rows)
        jsonDecode(row.payloadJson) as Map<String, dynamic>,
    ];
  }

  Future<void> savePending({
    required String userId,
    required String entityType,
    required String recordId,
    required String? parentId,
    required Map<String, dynamic> localRecord,
    required Map<String, dynamic> remotePayload,
    required SyncOperation operation,
    DateTime? baseUpdatedAt,
  }) async {
    final now = DateTime.now().toUtc();
    final existing = await _mutation(userId, entityType, recordId);
    final effectiveOperation =
        existing?.operation == 'create' && operation == SyncOperation.update
        ? SyncOperation.create
        : operation;
    await database.transaction(() async {
      await database
          .into(database.cachedRecords)
          .insertOnConflictUpdate(
            CachedRecordsCompanion.insert(
              userId: userId,
              entityType: entityType,
              recordId: recordId,
              parentId: Value(parentId),
              payloadJson: jsonEncode(localRecord),
              syncStatus: _localStatus(effectiveOperation).databaseValue,
              cachedAt: now,
            ),
          );
      await database
          .into(database.pendingMutations)
          .insertOnConflictUpdate(
            PendingMutationsCompanion.insert(
              mutationId: '$userId:$entityType:$recordId',
              userId: userId,
              entityType: entityType,
              recordId: recordId,
              operation: effectiveOperation.databaseValue,
              payloadJson: jsonEncode(remotePayload),
              baseUpdatedAt: Value(existing?.baseUpdatedAt ?? baseUpdatedAt),
              status: const Value('pending'),
              attempts: Value(existing?.attempts ?? 0),
              lastError: const Value(null),
              createdAt: existing?.createdAt ?? now,
              updatedAt: now,
            ),
          );
    });
  }

  Future<void> markPendingDelete({
    required String userId,
    required String entityType,
    required String recordId,
    required String? parentId,
    required Map<String, dynamic> remotePayload,
    DateTime? baseUpdatedAt,
  }) async {
    final existing = await _mutation(userId, entityType, recordId);
    if (existing?.operation == SyncOperation.create.databaseValue) {
      await database.transaction(() async {
        await (database.delete(
          database.pendingMutations,
        )..where((row) => row.mutationId.equals(existing!.mutationId))).go();
        await _deleteRecord(userId, entityType, recordId);
      });
      return;
    }
    final current = await readRecord(
      userId: userId,
      entityType: entityType,
      recordId: recordId,
    );
    await savePending(
      userId: userId,
      entityType: entityType,
      recordId: recordId,
      parentId: parentId,
      localRecord: current ?? {'id': recordId},
      remotePayload: remotePayload,
      operation: SyncOperation.delete,
      baseUpdatedAt: baseUpdatedAt,
    );
  }

  Future<List<PendingMutation>> pendingForUser(String userId) =>
      (database.select(database.pendingMutations)
            ..where(
              (row) => row.userId.equals(userId) & row.status.equals('pending'),
            )
            ..orderBy([(row) => OrderingTerm.asc(row.createdAt)]))
          .get();

  Stream<List<PendingMutation>> watchForUser(String userId) => (database.select(
    database.pendingMutations,
  )..where((row) => row.userId.equals(userId))).watch();

  Future<void> markSynced(PendingMutation mutation) async {
    await database.transaction(() async {
      await (database.delete(
        database.pendingMutations,
      )..where((row) => row.mutationId.equals(mutation.mutationId))).go();
      if (mutation.operation == SyncOperation.delete.databaseValue) {
        await _deleteRecord(
          mutation.userId,
          mutation.entityType,
          mutation.recordId,
        );
      } else {
        await (database.update(database.cachedRecords)..where(
              (row) =>
                  row.userId.equals(mutation.userId) &
                  row.entityType.equals(mutation.entityType) &
                  row.recordId.equals(mutation.recordId),
            ))
            .write(
              CachedRecordsCompanion(
                syncStatus: Value(LocalSyncStatus.synced.databaseValue),
              ),
            );
      }
    });
  }

  Future<void> markFailed(PendingMutation mutation, String message) async {
    final now = DateTime.now().toUtc();
    await database.transaction(() async {
      await (database.update(
        database.pendingMutations,
      )..where((row) => row.mutationId.equals(mutation.mutationId))).write(
        PendingMutationsCompanion(
          status: const Value('failed'),
          attempts: Value(mutation.attempts + 1),
          lastError: Value(message),
          updatedAt: Value(now),
        ),
      );
      await (database.update(database.cachedRecords)..where(
            (row) =>
                row.userId.equals(mutation.userId) &
                row.entityType.equals(mutation.entityType) &
                row.recordId.equals(mutation.recordId),
          ))
          .write(
            CachedRecordsCompanion(
              syncStatus: Value(LocalSyncStatus.failed.databaseValue),
            ),
          );
    });
  }

  Future<void> retryFailed(String userId) async {
    await (database.update(database.pendingMutations)..where(
          (row) => row.userId.equals(userId) & row.status.equals('failed'),
        ))
        .write(
          PendingMutationsCompanion(
            status: const Value('pending'),
            lastError: const Value(null),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
  }

  Future<void> removeRecord({
    required String userId,
    required String entityType,
    required String recordId,
  }) => _deleteRecord(userId, entityType, recordId);

  Future<CachedRecord?> _record(
    String userId,
    String entityType,
    String recordId,
  ) =>
      (database.select(database.cachedRecords)..where(
            (row) =>
                row.userId.equals(userId) &
                row.entityType.equals(entityType) &
                row.recordId.equals(recordId),
          ))
          .getSingleOrNull();

  Future<PendingMutation?> _mutation(
    String userId,
    String entityType,
    String recordId,
  ) =>
      (database.select(database.pendingMutations)..where(
            (row) =>
                row.userId.equals(userId) &
                row.entityType.equals(entityType) &
                row.recordId.equals(recordId),
          ))
          .getSingleOrNull();

  Future<void> _deleteRecord(
    String userId,
    String entityType,
    String recordId,
  ) async {
    await (database.delete(database.cachedRecords)..where(
          (row) =>
              row.userId.equals(userId) &
              row.entityType.equals(entityType) &
              row.recordId.equals(recordId),
        ))
        .go();
  }

  LocalSyncStatus _localStatus(SyncOperation operation) => switch (operation) {
    SyncOperation.create => LocalSyncStatus.pendingCreate,
    SyncOperation.update => LocalSyncStatus.pendingUpdate,
    SyncOperation.delete => LocalSyncStatus.pendingDelete,
  };
}

final offlineStoreProvider = Provider<OfflineStore>(
  (ref) => OfflineStore(ref.watch(appDatabaseProvider)),
);
