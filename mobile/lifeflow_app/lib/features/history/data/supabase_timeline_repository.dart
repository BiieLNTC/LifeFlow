import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeflow_app/core/supabase/supabase_provider.dart';
import 'package:lifeflow_app/core/sync/offline_repository_support.dart';
import 'package:lifeflow_app/core/sync/offline_store.dart';
import 'package:lifeflow_app/features/history/domain/timeline_entry.dart';
import 'package:lifeflow_app/features/history/domain/timeline_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final timelineRepositoryProvider = Provider<TimelineRepository>(
  (ref) => SupabaseTimelineRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(offlineStoreProvider),
  ),
);

class SupabaseTimelineRepository implements TimelineRepository {
  SupabaseTimelineRepository(this.client, OfflineStore store)
    : _offline = OfflineRepositorySupport(client, store);
  final SupabaseClient client;
  final OfflineRepositorySupport _offline;

  @override
  Future<List<TimelineEntry>> getTimeline(
    String vehicleId, {
    required int offset,
    required int limit,
  }) async {
    try {
      final rows = await _offline.readList(
        entityType: 'timeline',
        parentId: vehicleId,
        cachedOffset: offset,
        cachedLimit: limit,
        sortCached: _compareRows,
        replaceCached: false,
        remote: () async {
          final remote = await client
              .from('vehicle_timeline')
              .select()
              .eq('vehicle_id', vehicleId)
              .order('occurred_on', ascending: false)
              .order('created_at', ascending: false)
              .order('event_type')
              .order('event_id')
              .range(offset, offset + limit - 1);
          return [
            for (final row in remote)
              <String, dynamic>{
                ...row,
                'id': '${row['event_type']}:${row['event_id']}',
              },
          ];
        },
      );
      return rows.map(_fromJson).toList(growable: false);
    } on PostgrestException catch (error) {
      throw TimelineFailure(
        error.code == '42501'
            ? 'Você não tem permissão para acessar este histórico.'
            : 'Não foi possível carregar o histórico.',
      );
    } catch (error) {
      if (error is TimelineFailure) rethrow;
      throw const TimelineFailure(
        'Não foi possível conectar ao serviço. Verifique sua internet.',
      );
    }
  }

  TimelineEntry _fromJson(Map<String, dynamic> json) => TimelineEntry(
    id: json['event_id'],
    vehicleId: json['vehicle_id'],
    type: TimelineEventType.fromDatabase(json['event_type']),
    date: DateTime.parse(json['occurred_on']),
    title: json['title'],
    secondaryText: json['secondary_text'],
    category: json['category'],
    odometer: json['odometer'],
    amount: _number(json['amount']),
    createdAt: DateTime.parse(json['created_at']).toUtc(),
  );

  double _number(Object value) =>
      value is num ? value.toDouble() : double.parse(value as String);

  int _compareRows(Map<String, dynamic> a, Map<String, dynamic> b) {
    final date = (b['occurred_on'] as String).compareTo(
      a['occurred_on'] as String,
    );
    if (date != 0) return date;
    final created = (b['created_at'] as String).compareTo(
      a['created_at'] as String,
    );
    if (created != 0) return created;
    final type = (a['event_type'] as String).compareTo(
      b['event_type'] as String,
    );
    if (type != 0) return type;
    return (a['event_id'] as String).compareTo(b['event_id'] as String);
  }
}
