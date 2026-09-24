import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeflow_app/core/supabase/supabase_provider.dart';
import 'package:lifeflow_app/core/sync/offline_repository_support.dart';
import 'package:lifeflow_app/core/sync/offline_store.dart';
import 'package:lifeflow_app/core/sync/sync_models.dart';
import 'package:lifeflow_app/features/reminders/domain/reminder.dart';
import 'package:lifeflow_app/features/reminders/domain/reminder_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseReminderRepository(
    client,
    OfflineRepositorySupport(client, ref.watch(offlineStoreProvider)),
  );
});

class SupabaseReminderRepository implements ReminderRepository {
  SupabaseReminderRepository(this.client, this.offline);
  final SupabaseClient client;
  final OfflineRepositorySupport offline;

  @override
  Future<List<Reminder>> getReminders(String vehicleId) => _guard(() async {
    final rows = await offline.readList(
      entityType: 'reminder',
      parentId: vehicleId,
      remote: () async =>
          (await client
                  .from('reminder_details')
                  .select()
                  .eq('vehicle_id', vehicleId)
                  .order('status')
                  .order('target_date')
                  .order('target_odometer'))
              .cast<Map<String, dynamic>>(),
    );
    return rows.map(_fromJson).toList();
  });

  @override
  Future<Reminder> getReminder(String id) => _fetch(id);

  @override
  Future<Reminder> saveReminder(String id, ReminderDraft draft) =>
      _guard(() async {
        final payload = {
          'id': id,
          'vehicle_id': draft.vehicleId,
          'description': draft.description.trim(),
          'target_odometer': draft.targetOdometer,
          'target_date': _date(draft.targetDate),
          'origin_maintenance_id': draft.originMaintenanceId,
          'status': draft.status.databaseValue,
          'deleted_at': null,
        };
        final previous = await offline.store.readRecord(
          userId: offline.userId,
          entityType: 'reminder',
          recordId: id,
        );
        final local = await _localJson(id, draft, previous: previous);
        final row = await offline.save(
          entityType: 'reminder',
          recordId: id,
          parentId: draft.vehicleId,
          localRecord: local,
          remotePayload: payload,
          remote: () async {
            await client.from('reminders').upsert(payload);
            return _fetchRemote(id);
          },
        );
        return _fromJson(row);
      });

  @override
  Future<Reminder> setCompleted(String id, {required bool completed}) =>
      _guard(() async {
        final previous = await offline.store.readRecord(
          userId: offline.userId,
          entityType: 'reminder',
          recordId: id,
        );
        if (previous == null) {
          return _fromJson(await _fetchRemote(id));
        }
        final status = completed ? 'completed' : 'active';
        final payload = {
          'id': id,
          'vehicle_id': previous['vehicle_id'],
          'description': previous['description'],
          'target_odometer': previous['target_odometer'],
          'target_date': previous['target_date'],
          'origin_maintenance_id': previous['origin_maintenance_id'],
          'status': status,
          'deleted_at': null,
        };
        final local = Map<String, dynamic>.from(previous)
          ..['status'] = status
          ..['visual_status'] = completed ? 'completed' : _urgency(previous)
          ..['updated_at'] = DateTime.now().toUtc().toIso8601String();
        final row = await offline.save(
          entityType: 'reminder',
          recordId: id,
          parentId: previous['vehicle_id'] as String,
          localRecord: local,
          remotePayload: payload,
          operation: SyncOperation.update,
          remote: () async {
            await client
                .from('reminders')
                .update({'status': status})
                .eq('id', id)
                .select('id')
                .single();
            return _fetchRemote(id);
          },
        );
        return _fromJson(row);
      });

  @override
  Future<void> deleteReminder(String id) => _guard(() async {
    final previous = await offline.store.readRecord(
      userId: offline.userId,
      entityType: 'reminder',
      recordId: id,
    );
    await offline.delete(
      entityType: 'reminder',
      recordId: id,
      parentId: previous?['vehicle_id'] as String?,
      remote: () async {
        await client
            .from('reminders')
            .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
            .eq('id', id)
            .select('id')
            .single();
      },
    );
  });

  Future<Reminder> _fetch(String id) => _guard(
    () async => _fromJson(
      await offline.readOne(
        entityType: 'reminder',
        recordId: id,
        remote: () => _fetchRemote(id),
      ),
    ),
  );

  Future<Map<String, dynamic>> _fetchRemote(String id) =>
      client.from('reminder_details').select().eq('id', id).single();

  Future<Map<String, dynamic>> _localJson(
    String id,
    ReminderDraft draft, {
    Map<String, dynamic>? previous,
  }) async {
    final vehicle = await offline.store.readRecord(
      userId: offline.userId,
      entityType: 'vehicle',
      recordId: draft.vehicleId,
    );
    final currentOdometer =
        vehicle?['current_odometer'] as int? ??
        previous?['current_odometer'] as int? ??
        0;
    final now = DateTime.now().toUtc().toIso8601String();
    final row = <String, dynamic>{
      'id': id,
      'vehicle_id': draft.vehicleId,
      'description': draft.description.trim(),
      'target_odometer': draft.targetOdometer,
      'target_date': _date(draft.targetDate),
      'origin_maintenance_id': draft.originMaintenanceId,
      'status': draft.status.databaseValue,
      'current_odometer': currentOdometer,
      'remaining_km': draft.targetOdometer == null
          ? null
          : draft.targetOdometer! - currentOdometer,
      'remaining_days': draft.targetDate == null
          ? null
          : DateTime(
              draft.targetDate!.year,
              draft.targetDate!.month,
              draft.targetDate!.day,
            ).difference(DateTime.now()).inDays,
      'created_at': previous?['created_at'] ?? now,
      'updated_at': now,
      'deleted_at': null,
    };
    row['visual_status'] = draft.status == ReminderStatus.completed
        ? 'completed'
        : _urgency(row);
    return row;
  }

  String _urgency(Map<String, dynamic> row) {
    final remainingKm = row['remaining_km'] as int?;
    final remainingDays = row['remaining_days'] as int?;
    if ((remainingKm != null && remainingKm <= 0) ||
        (remainingDays != null && remainingDays <= 0)) {
      return 'overdue';
    }
    if ((remainingKm != null && remainingKm <= 1000) ||
        (remainingDays != null && remainingDays <= 30)) {
      return 'near';
    }
    return 'upcoming';
  }

  Reminder _fromJson(Map<String, dynamic> json) => Reminder(
    id: json['id'],
    vehicleId: json['vehicle_id'],
    description: json['description'],
    targetOdometer: json['target_odometer'],
    targetDate: json['target_date'] == null
        ? null
        : DateTime.parse(json['target_date']),
    status: ReminderStatus.fromDatabase(json['status']),
    urgency: ReminderUrgency.fromDatabase(json['visual_status']),
    originMaintenanceId: json['origin_maintenance_id'],
    currentOdometer: json['current_odometer'],
    remainingKm: json['remaining_km'],
    remainingDays: json['remaining_days'],
    createdAt: DateTime.parse(json['created_at']).toUtc(),
    updatedAt: DateTime.parse(json['updated_at']).toUtc(),
  );

  String? _date(DateTime? date) => date?.toIso8601String().split('T').first;

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on PostgrestException catch (error) {
      throw ReminderFailure(
        error.code == '42501'
            ? 'Você não tem permissão para este lembrete.'
            : 'Revise os dados do lembrete.',
      );
    } catch (error) {
      if (error is ReminderFailure) rethrow;
      throw const ReminderFailure('Não foi possível conectar ao serviço.');
    }
  }
}
