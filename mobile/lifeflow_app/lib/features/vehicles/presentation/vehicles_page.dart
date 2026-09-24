import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeflow_app/core/navigation/app_bottom_nav.dart';
import 'package:lifeflow_app/core/navigation/app_tab.dart';
import 'package:lifeflow_app/core/theme/app_palette.dart';
import 'package:lifeflow_app/features/notifications/presentation/notification_bell.dart';
import 'package:lifeflow_app/features/vehicles/domain/vehicle.dart';
import 'package:lifeflow_app/features/vehicles/presentation/vehicle_formatters.dart';
import 'package:lifeflow_app/features/vehicles/presentation/vehicles_controller.dart';
import 'package:lifeflow_app/core/widgets/lifeflow_wordmark.dart';

class VehiclesPage extends ConsumerWidget {
  const VehiclesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicles = ref.watch(vehiclesControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const LifeFlowWordmark(height: 14),
        actions: const [NotificationBell()],
      ),
      body: SafeArea(
        child: vehicles.when(
          loading: () => const _LoadingState(),
          error: (error, _) => _ErrorState(
            onRetry: () =>
                ref.read(vehiclesControllerProvider.notifier).reload(),
          ),
          data: (items) => items.isEmpty
              ? _EmptyState(onCreate: () => context.push('/vehicles/new'))
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(vehiclesControllerProvider.notifier).reload(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 104),
                    children: [
                      Text(
                        'Seus veículos',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tudo o que importa, começando por quem está na garagem.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 28),
                      for (final vehicle in items) ...[
                        _VehicleTile(vehicle: vehicle),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
        ),
      ),
      floatingActionButton: vehicles.value?.isNotEmpty == true
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/vehicles/new'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('VEÍCULO'),
            )
          : null,
      bottomNavigationBar: const AppBottomNav(currentTab: AppTab.vehicles),
    );
  }
}

class _VehicleTile extends StatelessWidget {
  const _VehicleTile({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/vehicles/${vehicle.id}'),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  vehicle.type == VehicleType.car
                      ? Icons.directions_car_filled_rounded
                      : Icons.two_wheeler_rounded,
                  color: context.colors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.nickname,
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vehicle.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      formatOdometer(vehicle.currentOdometer),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: 'Carregando veículos',
        child: const CircularProgressIndicator(),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 64,
              color: context.colors.textSecondary,
            ),
            const SizedBox(height: 24),
            Text(
              'Sua garagem começa aqui.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            Text(
              'Cadastre seu primeiro veículo para construir um histórico confiável.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('ADICIONAR VEÍCULO'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
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
              'Não foi possível carregar seus veículos.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Confira sua conexão e tente novamente.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
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
}
