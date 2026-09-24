import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeflow_app/core/database/app_database.dart';
import 'package:lifeflow_app/core/sync/offline_store.dart';
import 'package:lifeflow_app/core/sync/sync_models.dart';

void main() {
  late AppDatabase database;
  late OfflineStore store;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    store = OfflineStore(database);
  });

  tearDown(() => database.close());

  test('coalesces an offline create followed by an update', () async {
    await store.savePending(
      userId: 'user-1',
      entityType: 'vehicle',
      recordId: 'vehicle-1',
      parentId: null,
      localRecord: const {'id': 'vehicle-1', 'nickname': 'I30'},
      remotePayload: const {'id': 'vehicle-1', 'nickname': 'I30'},
      operation: SyncOperation.create,
    );
    await store.savePending(
      userId: 'user-1',
      entityType: 'vehicle',
      recordId: 'vehicle-1',
      parentId: null,
      localRecord: const {'id': 'vehicle-1', 'nickname': 'Meu i30'},
      remotePayload: const {'id': 'vehicle-1', 'nickname': 'Meu i30'},
      operation: SyncOperation.update,
    );

    final pending = await store.pendingForUser('user-1');
    final local = await store.readRecord(
      userId: 'user-1',
      entityType: 'vehicle',
      recordId: 'vehicle-1',
    );

    expect(pending, hasLength(1));
    expect(pending.single.operation, 'create');
    expect(jsonDecode(pending.single.payloadJson)['nickname'], 'Meu i30');
    expect(local?['nickname'], 'Meu i30');
  });

  test('deleting an unsynced create removes it instead of queueing', () async {
    await store.savePending(
      userId: 'user-1',
      entityType: 'expense',
      recordId: 'expense-1',
      parentId: 'vehicle-1',
      localRecord: const {'id': 'expense-1', 'vehicle_id': 'vehicle-1'},
      remotePayload: const {'id': 'expense-1', 'vehicle_id': 'vehicle-1'},
      operation: SyncOperation.create,
    );

    await store.markPendingDelete(
      userId: 'user-1',
      entityType: 'expense',
      recordId: 'expense-1',
      parentId: 'vehicle-1',
      remotePayload: const {},
    );

    expect(await store.pendingForUser('user-1'), isEmpty);
    expect(
      await store.readRecord(
        userId: 'user-1',
        entityType: 'expense',
        recordId: 'expense-1',
      ),
      isNull,
    );
  });

  test('marks conflicts as failed and preserves the local payload', () async {
    await store.cacheRecords(
      userId: 'user-1',
      entityType: 'vehicle',
      records: const [
        {
          'id': 'vehicle-1',
          'nickname': 'Servidor',
          'updated_at': '2026-09-20T12:00:00Z',
        },
      ],
    );
    await store.savePending(
      userId: 'user-1',
      entityType: 'vehicle',
      recordId: 'vehicle-1',
      parentId: null,
      localRecord: const {
        'id': 'vehicle-1',
        'nickname': 'Local',
        'updated_at': '2026-09-20T12:00:00Z',
      },
      remotePayload: const {'id': 'vehicle-1', 'nickname': 'Local'},
      operation: SyncOperation.update,
      baseUpdatedAt: DateTime.utc(2026, 9, 20, 12),
    );
    final mutation = (await store.pendingForUser('user-1')).single;

    await store.markFailed(mutation, 'Conflito de edi\u00e7\u00e3o.');

    expect(await store.pendingForUser('user-1'), isEmpty);
    final allMutations = await store.watchForUser('user-1').first;
    expect(allMutations.single.status, 'failed');
    expect(allMutations.single.lastError, 'Conflito de edi\u00e7\u00e3o.');
    final local = await store.readRecord(
      userId: 'user-1',
      entityType: 'vehicle',
      recordId: 'vehicle-1',
    );
    expect(local?['nickname'], 'Local');
  });

  test('replacing a server snapshot keeps pending local records', () async {
    await store.cacheRecords(
      userId: 'user-1',
      entityType: 'expense',
      records: const [
        {'id': 'old', 'vehicle_id': 'vehicle-1'},
      ],
      parentId: (row) => row['vehicle_id'] as String,
    );
    await store.savePending(
      userId: 'user-1',
      entityType: 'expense',
      recordId: 'local',
      parentId: 'vehicle-1',
      localRecord: const {'id': 'local', 'vehicle_id': 'vehicle-1'},
      remotePayload: const {'id': 'local', 'vehicle_id': 'vehicle-1'},
      operation: SyncOperation.create,
    );

    await store.cacheRecords(
      userId: 'user-1',
      entityType: 'expense',
      records: const [
        {'id': 'new', 'vehicle_id': 'vehicle-1'},
      ],
      parentId: (row) => row['vehicle_id'] as String,
      replaceSynced: true,
      scopeParentId: 'vehicle-1',
    );

    final cached = await store.readRecords(
      userId: 'user-1',
      entityType: 'expense',
      parentId: 'vehicle-1',
    );
    expect(cached.map((row) => row['id']), containsAll(['new', 'local']));
    expect(cached.map((row) => row['id']), isNot(contains('old')));
  });

  test('advances cached vehicle odometer without lowering it', () async {
    await store.cacheRecords(
      userId: 'user-1',
      entityType: 'vehicle',
      records: const [
        {
          'id': 'vehicle-1',
          'current_odometer': 10000,
          'updated_at': '2026-09-20T12:00:00Z',
        },
      ],
    );
    await store.cacheRecords(
      userId: 'user-1',
      entityType: 'dashboard',
      records: const [
        {
          'id': 'vehicle-1',
          'vehicle_id': 'vehicle-1',
          'current_odometer': 10000,
          'next_reminder_odometer': 11000,
          'next_reminder_remaining_km': 1000,
          'next_reminder_status': 'near',
        },
      ],
      parentId: (row) => row['vehicle_id'] as String,
    );

    await store.advanceVehicleOdometer(
      userId: 'user-1',
      vehicleId: 'vehicle-1',
      odometer: 10500,
    );
    await store.advanceVehicleOdometer(
      userId: 'user-1',
      vehicleId: 'vehicle-1',
      odometer: 10200,
    );

    final vehicle = await store.readRecord(
      userId: 'user-1',
      entityType: 'vehicle',
      recordId: 'vehicle-1',
    );
    expect(vehicle?['current_odometer'], 10500);
    expect(vehicle?['updated_at'], '2026-09-20T12:00:00Z');
    final dashboard = await store.readRecord(
      userId: 'user-1',
      entityType: 'dashboard',
      recordId: 'vehicle-1',
    );
    expect(dashboard?['current_odometer'], 10500);
    expect(dashboard?['next_reminder_remaining_km'], 500);
  });

  test('also advances the payload of a pending vehicle creation', () async {
    await store.savePending(
      userId: 'user-1',
      entityType: 'vehicle',
      recordId: 'vehicle-1',
      parentId: null,
      localRecord: const {'id': 'vehicle-1', 'current_odometer': 10000},
      remotePayload: const {'id': 'vehicle-1', 'current_odometer': 10000},
      operation: SyncOperation.create,
    );

    await store.advanceVehicleOdometer(
      userId: 'user-1',
      vehicleId: 'vehicle-1',
      odometer: 10500,
    );

    final mutation = (await store.pendingForUser('user-1')).single;
    expect(jsonDecode(mutation.payloadJson)['current_odometer'], 10500);
  });
}
