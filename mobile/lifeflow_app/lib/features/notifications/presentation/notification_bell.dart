import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeflow_app/core/theme/app_palette.dart';
import 'package:lifeflow_app/features/notifications/domain/notification_item.dart';
import 'package:lifeflow_app/features/notifications/presentation/notifications_controller.dart';

/// Sino das telas de topo, com badge de contagem. Ao voltar da central relê a
/// contagem, pois o usuário pode ter resolvido itens por lá.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(notificationCountProvider);
    final severity = ref.watch(notificationTopSeverityProvider);
    final colors = context.colors;
    final badgeColor = switch (severity) {
      NotificationSeverity.critical => colors.critical,
      NotificationSeverity.warning => colors.warning,
      _ => colors.primary,
    };
    return IconButton(
      tooltip: count == 0
          ? 'Notificações'
          : 'Notificações ($count)',
      onPressed: () async {
        await context.push('/notifications');
        ref.invalidate(notificationsProvider);
      },
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text(count > 99 ? '99+' : '$count'),
        backgroundColor: badgeColor,
        textColor: severity == NotificationSeverity.critical
            ? Colors.white
            : colors.background,
        child: const Icon(Icons.notifications_none_rounded),
      ),
    );
  }
}
