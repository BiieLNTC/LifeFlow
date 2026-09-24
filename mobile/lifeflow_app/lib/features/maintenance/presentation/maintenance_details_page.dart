import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeflow_app/core/theme/app_palette.dart';
import 'package:lifeflow_app/features/attachments/presentation/maintenance_attachments_section.dart';
import 'package:lifeflow_app/features/maintenance/domain/maintenance.dart';
import 'package:lifeflow_app/features/maintenance/domain/maintenance_repository.dart';
import 'package:lifeflow_app/features/maintenance/presentation/maintenance_controller.dart';
import 'package:lifeflow_app/features/maintenance/presentation/maintenance_form_page.dart';
import 'package:lifeflow_app/features/vehicles/presentation/vehicle_formatters.dart';

class MaintenanceDetailsPage extends ConsumerWidget {
  const MaintenanceDetailsPage({
    required this.vehicleId,
    required this.maintenanceId,
    super.key,
  });
  final String vehicleId;
  final String maintenanceId;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover manutenção?'),
        content: const Text('Ela deixará de aparecer no histórico do veículo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'REMOVER',
              style: TextStyle(color: context.colors.critical),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref
          .read(maintenancesProvider(vehicleId).notifier)
          .delete(maintenanceId);
      if (context.mounted) context.pop();
    } on MaintenanceFailure catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(maintenanceDetailsProvider(maintenanceId));
    return state.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: OutlinedButton(
            onPressed: () =>
                ref.invalidate(maintenanceDetailsProvider(maintenanceId)),
            child: const Text('TENTAR NOVAMENTE'),
          ),
        ),
      ),
      data: (maintenance) => Scaffold(
        appBar: AppBar(
          title: const Text('Manutenção'),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  context.push(
                    '/vehicles/$vehicleId/maintenances/$maintenanceId/edit',
                  );
                } else {
                  _delete(context, ref);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Editar')),
                PopupMenuItem(value: 'delete', child: Text('Remover')),
              ],
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            Text(
              maintenance.type.label,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${formatDate(maintenance.date)} • ${formatOdometer(maintenance.odometer)}',
            ),
            const SizedBox(height: 28),
            for (final item in maintenance.items) _ItemView(item: item),
            const Divider(height: 36),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  formatCurrency(maintenance.totalAmount),
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            if (maintenance.workshop != null) ...[
              const SizedBox(height: 28),
              Text('Oficina', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text(maintenance.workshop!),
            ],
            if (maintenance.notes != null) ...[
              const SizedBox(height: 20),
              Text(
                'Observações',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(maintenance.notes!),
            ],
            const Divider(height: 48),
            MaintenanceAttachmentsSection(
              vehicleId: vehicleId,
              maintenanceId: maintenanceId,
            ),
          ],
        ),
      ),
    );
  }
}

class MaintenanceEditRoutePage extends ConsumerWidget {
  const MaintenanceEditRoutePage({
    required this.vehicleId,
    required this.maintenanceId,
    super.key,
  });
  final String vehicleId;
  final String maintenanceId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(maintenanceDetailsProvider(maintenanceId))
      .when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, _) => const Scaffold(
          body: Center(child: Text('Manutenção indisponível.')),
        ),
        data: (item) =>
            MaintenanceFormPage(vehicleId: vehicleId, initialMaintenance: item),
      );
}

class _ItemView extends StatelessWidget {
  const _ItemView({required this.item});
  final MaintenanceItem item;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.description,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text('${item.category.label} • ${formatCurrency(item.total)}'),
        if (item.nextReplacementOdometer != null)
          Text(
            'Próxima troca: ${formatOdometer(item.nextReplacementOdometer!)}',
          ),
        if (item.nextReplacementDate != null)
          Text('Próxima troca: ${formatDate(item.nextReplacementDate!)}'),
      ],
    ),
  );
}
