import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeflow_app/core/theme/app_palette.dart';
import 'package:lifeflow_app/features/reminders/domain/reminder.dart';
import 'package:lifeflow_app/features/reminders/domain/reminder_repository.dart';
import 'package:lifeflow_app/features/reminders/presentation/reminders_controller.dart';
import 'package:lifeflow_app/features/vehicles/presentation/vehicle_formatters.dart';

class RemindersPage extends ConsumerWidget {
  const RemindersPage({required this.vehicleId, super.key});
  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(remindersProvider(vehicleId));
    return Scaffold(
      appBar: AppBar(title: const Text('Lembretes')),
      body: SafeArea(
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: OutlinedButton(
              onPressed: () =>
                  ref.read(remindersProvider(vehicleId).notifier).reload(),
              child: const Text('TENTAR NOVAMENTE'),
            ),
          ),
          data: (items) => items.isEmpty
              ? _Empty(
                  onCreate: () =>
                      context.push('/vehicles/$vehicleId/reminders/new'),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(remindersProvider(vehicleId).notifier).reload(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 104),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _ReminderTile(
                      reminder: items[index],
                      onEdit: () => context.push(
                        '/vehicles/$vehicleId/reminders/${items[index].id}/edit',
                      ),
                      onToggle: () => _toggle(context, ref, items[index]),
                      onDelete: () => _delete(context, ref, items[index]),
                    ),
                  ),
                ),
        ),
      ),
      floatingActionButton: state.value?.isNotEmpty == true
          ? FloatingActionButton.extended(
              onPressed: () =>
                  context.push('/vehicles/$vehicleId/reminders/new'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('LEMBRETE'),
            )
          : null,
    );
  }

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    Reminder reminder,
  ) async {
    try {
      await ref
          .read(remindersProvider(vehicleId).notifier)
          .setCompleted(
            reminder,
            completed: reminder.status != ReminderStatus.completed,
          );
    } on ReminderFailure catch (failure) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failure.message)));
      }
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Reminder reminder,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remover lembrete?'),
        content: Text(reminder.description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('REMOVER'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(remindersProvider(vehicleId).notifier).delete(reminder.id);
    }
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.reminder,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });
  final Reminder reminder;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = switch (reminder.urgency) {
      ReminderUrgency.upcoming => context.colors.primary,
      ReminderUrgency.near => context.colors.warning,
      ReminderUrgency.overdue => context.colors.critical,
      ReminderUrgency.completed => context.colors.textSecondary,
    };
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 8, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.circle, size: 12, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.description,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _targets(reminder),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _status(reminder),
                    style: TextStyle(color: color, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'toggle') onToggle();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Editar')),
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(
                    reminder.status == ReminderStatus.completed
                        ? 'Reabrir'
                        : 'Concluir',
                  ),
                ),
                const PopupMenuItem(value: 'delete', child: Text('Remover')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _targets(Reminder item) {
    final values = <String>[];
    if (item.targetOdometer != null) {
      values.add(formatOdometer(item.targetOdometer!));
    }
    if (item.targetDate != null) values.add(formatDate(item.targetDate!));
    return values.join(' • ');
  }

  String _status(Reminder item) {
    if (item.urgency == ReminderUrgency.completed) return 'Concluído';
    if (item.urgency == ReminderUrgency.overdue) return 'Vencido';
    final parts = <String>[];
    if (item.remainingKm != null) {
      parts.add('faltam ${formatOdometer(item.remainingKm!)}');
    }
    if (item.remainingDays != null) {
      parts.add('faltam ${item.remainingDays} dias');
    }
    return parts.isEmpty ? item.urgency.label : parts.join(' • ');
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 60,
            color: context.colors.textSecondary,
          ),
          const SizedBox(height: 20),
          Text(
            'Nenhum cuidado programado.',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Crie um lembrete por quilometragem, data ou ambos.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('NOVO LEMBRETE'),
          ),
        ],
      ),
    ),
  );
}
