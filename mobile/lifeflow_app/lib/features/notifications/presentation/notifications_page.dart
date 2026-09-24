import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeflow_app/core/theme/app_palette.dart';
import 'package:lifeflow_app/features/notifications/domain/notification_item.dart';
import 'package:lifeflow_app/features/notifications/presentation/notifications_controller.dart';
import 'package:lifeflow_app/features/vehicles/presentation/vehicle_formatters.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);
    Future<void> reload() async {
      ref.invalidate(notificationsProvider);
      try {
        await ref.read(notificationsProvider.future);
      } catch (_) {
        // O erro já aparece no estado da tela.
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Notificações')),
      body: SafeArea(
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _ErrorState(onRetry: reload),
          data: (items) => RefreshIndicator(
            onRefresh: reload,
            child: items.isEmpty
                ? const _EmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _NotificationTile(
                      item: items[index],
                      onTap: () async {
                        final location = items[index].location;
                        if (location == null) return;
                        await context.push(location);
                        // O usuário pode ter resolvido o item no destino.
                        ref.invalidate(notificationsProvider);
                      },
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});
  final NotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tone = switch (item.severity) {
      NotificationSeverity.critical => colors.critical,
      NotificationSeverity.warning => colors.warning,
      NotificationSeverity.info => colors.primary,
    };
    final icon = switch (item.severity) {
      NotificationSeverity.critical => Icons.error_outline_rounded,
      NotificationSeverity.warning => Icons.warning_amber_rounded,
      NotificationSeverity.info => Icons.info_outline_rounded,
    };
    final due = item.dueDate;
    final hasTarget = item.location != null;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: hasTarget ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: tone),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.kind.label} · ${item.subtitle}'
                      '${due == null ? '' : ' · ${formatDate(due)}'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (hasTarget)
                Icon(
                  Icons.chevron_right_rounded,
                  color: colors.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    // Rolável para o pull-to-refresh funcionar também na lista vazia.
    builder: (context, constraints) => SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                size: 56,
                color: context.colors.textSecondary,
              ),
              const SizedBox(height: 20),
              Text(
                'Tudo em dia.',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Nada vencendo, nenhum orçamento no limite e nenhuma '
                'recorrência pendente.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 52,
            color: context.colors.warning,
          ),
          const SizedBox(height: 20),
          Text(
            'Não foi possível carregar as notificações.',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('TENTAR NOVAMENTE'),
          ),
        ],
      ),
    ),
  );
}
