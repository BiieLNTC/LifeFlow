import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeflow_app/core/theme/app_palette.dart';
import 'package:lifeflow_app/features/maintenance/domain/maintenance.dart';
import 'package:lifeflow_app/features/maintenance/presentation/maintenance_controller.dart';
import 'package:lifeflow_app/features/vehicles/presentation/vehicle_formatters.dart';

class MaintenancesPage extends ConsumerWidget {
  const MaintenancesPage({required this.vehicleId, super.key});
  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(maintenancesProvider(vehicleId));
    return Scaffold(
      appBar: AppBar(title: const Text('Manutenções')),
      body: SafeArea(
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _ErrorState(
            onRetry: () =>
                ref.read(maintenancesProvider(vehicleId).notifier).reload(),
          ),
          data: (items) => items.isEmpty
              ? _EmptyState(
                  onCreate: () =>
                      context.push('/vehicles/$vehicleId/maintenances/new'),
                )
              : RefreshIndicator(
                  onRefresh: () => ref
                      .read(maintenancesProvider(vehicleId).notifier)
                      .reload(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 104),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _MaintenanceTile(
                      maintenance: items[index],
                      onTap: () => context.push(
                        '/vehicles/$vehicleId/maintenances/${items[index].id}',
                      ),
                    ),
                  ),
                ),
        ),
      ),
      floatingActionButton: state.value?.isNotEmpty == true
          ? FloatingActionButton.extended(
              onPressed: () =>
                  context.push('/vehicles/$vehicleId/maintenances/new'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('MANUTENÇÃO'),
            )
          : null,
    );
  }
}

class _MaintenanceTile extends StatelessWidget {
  const _MaintenanceTile({required this.maintenance, required this.onTap});
  final Maintenance maintenance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = maintenance.items.length == 1
        ? maintenance.items.single.description
        : '${maintenance.items.first.description} + ${maintenance.items.length - 1}';
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(Icons.build_circle_outlined, color: context.colors.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${formatDate(maintenance.date)} • ${formatOdometer(maintenance.odometer)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                formatCurrency(maintenance.totalAmount),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});
  final VoidCallback onCreate;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.build_outlined,
            size: 60,
            color: context.colors.textSecondary,
          ),
          const SizedBox(height: 20),
          Text(
            'Nenhuma manutenção registrada.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Registre o primeiro cuidado deste veículo.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('NOVA MANUTENÇÃO'),
          ),
        ],
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;
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
          const SizedBox(height: 16),
          const Text('Não foi possível carregar as manutenções.'),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('TENTAR NOVAMENTE'),
          ),
        ],
      ),
    ),
  );
}
