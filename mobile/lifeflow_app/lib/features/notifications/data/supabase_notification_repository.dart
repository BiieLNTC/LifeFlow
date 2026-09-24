import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeflow_app/core/supabase/supabase_provider.dart';
import 'package:lifeflow_app/core/sync/offline_repository_support.dart';
import 'package:lifeflow_app/core/sync/offline_store.dart';
import 'package:lifeflow_app/features/notifications/domain/notification_item.dart';
import 'package:lifeflow_app/features/notifications/domain/notification_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseNotificationRepository(
    client,
    OfflineRepositorySupport(client, ref.watch(offlineStoreProvider)),
  );
});

class SupabaseNotificationRepository implements NotificationRepository {
  SupabaseNotificationRepository(this._client, this._offline);
  final SupabaseClient _client;
  final OfflineRepositorySupport _offline;

  @override
  Future<List<NotificationItem>> list() async {
    try {
      final rows = await _offline.readList(
        entityType: 'notification_items',
        parentId: null,
        // `vehicle_id` é dado de destino, não escopo de cache: o cache da view
        // inteira fica sob parent nulo (a leitura offline filtra por parent nulo).
        parentIdField: 'cache_scope',
        remote: () async {
          final remote = await _client.from('notification_items').select();
          return [
            for (final row in remote)
              <String, dynamic>{
                'id': '${row['kind']}:${row['target_id']}',
                ...row,
              },
          ];
        },
      );
      return sortNotifications(rows.map(_fromRow).whereType<NotificationItem>());
    } on PostgrestException catch (_) {
      throw const NotificationFailure(
        'Não foi possível carregar as notificações.',
      );
    } catch (_) {
      throw const NotificationFailure('Não foi possível conectar ao serviço.');
    }
  }

  /// Linha desconhecida (view evoluiu antes do app) é ignorada, não quebra a tela.
  NotificationItem? _fromRow(Map<String, dynamic> row) {
    final kind = NotificationKind.tryFromDatabase(row['kind'] as String? ?? '');
    final severity = NotificationSeverity.tryFromDatabase(
      row['severity'] as String? ?? '',
    );
    final targetId = row['target_id'] as String?;
    if (kind == null || severity == null || targetId == null) return null;
    final due = row['due_date'] as String?;
    return NotificationItem(
      kind: kind,
      title: row['title'] as String? ?? '',
      subtitle: row['subtitle'] as String? ?? '',
      severity: severity,
      targetId: targetId,
      dueDate: due == null ? null : DateTime.parse(due),
      vehicleId: row['vehicle_id'] as String?,
    );
  }
}
