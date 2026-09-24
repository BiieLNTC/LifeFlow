import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeflow_app/features/notifications/data/supabase_notification_repository.dart';
import 'package:lifeflow_app/features/notifications/domain/notification_item.dart';

/// `autoDispose`: cada vez que uma aba de topo é reaberta o sino relê a view.
final notificationsProvider =
    FutureProvider.autoDispose<List<NotificationItem>>(
      (ref) => ref.watch(notificationRepositoryProvider).list(),
    );

/// Contagem do badge; zera enquanto carrega ou em erro (o sino nunca alarma em falso).
final notificationCountProvider = Provider.autoDispose<int>(
  (ref) => ref.watch(notificationsProvider).value?.length ?? 0,
);

/// Pior severidade do conjunto — define a cor do badge.
final notificationTopSeverityProvider =
    Provider.autoDispose<NotificationSeverity?>((ref) {
      final items = ref.watch(notificationsProvider).value;
      if (items == null || items.isEmpty) return null;
      // A lista já vem ordenada por gravidade.
      return items.first.severity;
    });
