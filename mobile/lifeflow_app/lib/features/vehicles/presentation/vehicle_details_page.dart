import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeflow_app/core/theme/app_palette.dart';
import 'package:lifeflow_app/features/vehicles/domain/vehicle.dart';
import 'package:lifeflow_app/features/vehicles/domain/vehicle_repository.dart';
import 'package:lifeflow_app/features/vehicles/presentation/vehicle_form_page.dart';
import 'package:lifeflow_app/features/vehicles/presentation/vehicle_formatters.dart';
import 'package:lifeflow_app/features/vehicles/presentation/vehicles_controller.dart';

class VehicleDetailsPage extends ConsumerStatefulWidget {
  const VehicleDetailsPage({required this.vehicleId, super.key});

  final String vehicleId;

  @override
  ConsumerState<VehicleDetailsPage> createState() => _VehicleDetailsPageState();
}

class _VehicleDetailsPageState extends ConsumerState<VehicleDetailsPage> {
  bool _isDeleting = false;

  Future<void> _delete(Vehicle vehicle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover veículo?'),
        content: Text(
          '${vehicle.nickname} deixará de aparecer na sua garagem. O histórico será preservado.',
        ),
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

    if (confirmed != true || !mounted) return;
    setState(() => _isDeleting = true);

    try {
      await ref.read(vehiclesControllerProvider.notifier).delete(vehicle.id);
      if (mounted) context.go('/');
    } on VehicleFailure catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
      setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = ref.watch(vehicleDetailsProvider(widget.vehicleId));

    return vehicle.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: _DetailsError(
          onRetry: () =>
              ref.invalidate(vehicleDetailsProvider(widget.vehicleId)),
        ),
      ),
      data: (item) => Scaffold(
        appBar: AppBar(
          title: Text(item.nickname),
          actions: [
            PopupMenuButton<String>(
              enabled: !_isDeleting,
              onSelected: (action) {
                if (action == 'edit') {
                  context.push('/vehicles/${item.id}/edit');
                } else if (action == 'delete') {
                  _delete(item);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Editar')),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Remover',
                    style: TextStyle(color: context.colors.critical),
                  ),
                ),
              ],
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              Container(
                height: 210,
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  item.type == VehicleType.car
                      ? Icons.directions_car_filled_rounded
                      : Icons.two_wheeler_rounded,
                  size: 88,
                  color: context.colors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.description,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        if (item.version != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.version!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: context.colors.primary,
                        ),
                        SizedBox(width: 6),
                        Text('Ativo'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                formatOdometer(item.currentOdometer),
                style: Theme.of(context).textTheme.displaySmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'quilometragem atual',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 36),
              Material(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(20),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  leading: Icon(
                    Icons.history_rounded,
                    color: context.colors.primary,
                  ),
                  title: const Text('Histórico'),
                  subtitle: const Text('Toda a vida do veículo'),
                  trailing: Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/vehicles/${item.id}/history'),
                ),
              ),
              const SizedBox(height: 12),
              Material(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(20),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  leading: Icon(
                    Icons.build_circle_outlined,
                    color: context.colors.primary,
                  ),
                  title: const Text('Manutenções'),
                  subtitle: const Text('Serviços, peças e revisões'),
                  trailing: Icon(Icons.chevron_right_rounded),
                  onTap: () =>
                      context.push('/vehicles/${item.id}/maintenances'),
                ),
              ),
              const SizedBox(height: 12),
              Material(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(20),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  leading: Icon(
                    Icons.local_gas_station_rounded,
                    color: context.colors.primary,
                  ),
                  title: const Text('Abastecimentos'),
                  subtitle: const Text('Combustível e consumo'),
                  trailing: Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/vehicles/${item.id}/refuelings'),
                ),
              ),
              const SizedBox(height: 12),
              Material(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(20),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  leading: Icon(
                    Icons.receipt_long_rounded,
                    color: context.colors.primary,
                  ),
                  title: const Text('Despesas'),
                  subtitle: const Text('Seguro, impostos e outros custos'),
                  trailing: Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/vehicles/${item.id}/expenses'),
                ),
              ),
              const SizedBox(height: 12),
              Material(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(20),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  leading: Icon(
                    Icons.notifications_active_outlined,
                    color: context.colors.primary,
                  ),
                  title: const Text('Lembretes'),
                  subtitle: const Text('Cuidados por KM ou data'),
                  trailing: Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/vehicles/${item.id}/reminders'),
                ),
              ),
              const SizedBox(height: 36),
              Text(
                'Informações',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              _InfoRow(label: 'Tipo', value: item.type.label),
              if (item.manufactureYear != null || item.modelYear != null)
                _InfoRow(label: 'Ano', value: _yearText(item)),
              if (item.licensePlate != null)
                _InfoRow(label: 'Placa', value: item.licensePlate!),
              if (item.fuelType != null)
                _InfoRow(label: 'Combustível', value: item.fuelType!.label),
              if (item.purchaseDate != null)
                _InfoRow(
                  label: 'Data da compra',
                  value: formatDate(item.purchaseDate!),
                ),
              if (item.purchasePrice != null)
                _InfoRow(
                  label: 'Valor da compra',
                  value: formatCurrency(item.purchasePrice!),
                ),
              if (item.notes != null) ...[
                const SizedBox(height: 20),
                Text(
                  'Observações',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 6),
                Text(item.notes!),
              ],
              if (_isDeleting) ...[
                const SizedBox(height: 28),
                const LinearProgressIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _yearText(Vehicle vehicle) {
    if (vehicle.manufactureYear != null && vehicle.modelYear != null) {
      return '${vehicle.manufactureYear}/${vehicle.modelYear}';
    }
    return (vehicle.modelYear ?? vehicle.manufactureYear).toString();
  }
}

class VehicleEditRoutePage extends ConsumerWidget {
  const VehicleEditRoutePage({required this.vehicleId, super.key});

  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(vehicleDetailsProvider(vehicleId))
        .when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, _) => Scaffold(
            appBar: AppBar(),
            body: _DetailsError(
              onRetry: () => ref.invalidate(vehicleDetailsProvider(vehicleId)),
            ),
          ),
          data: (vehicle) => VehicleFormPage(initialVehicle: vehicle),
        );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsError extends StatelessWidget {
  const _DetailsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 52),
            const SizedBox(height: 16),
            const Text('Veículo não encontrado ou indisponível.'),
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
}
