import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeflow_app/core/theme/app_palette.dart';
import 'package:lifeflow_app/features/dashboard/domain/vehicle_dashboard.dart';
import 'package:lifeflow_app/features/dashboard/presentation/dashboard_controller.dart';

/// Bottom sheet único de registro rápido (Veículo + Finanças), acessível a
/// partir do botão central da navegação inferior em qualquer aba.
Future<void> showQuickAddSheet(
  BuildContext context,
  WidgetRef ref, {
  String? preferredVehicleId,
}) async {
  final vehicles = ref.read(dashboardProvider).value ?? const <VehicleDashboard>[];
  final vehicle = vehicles.isEmpty
      ? null
      : vehicles.firstWhere(
          (item) => item.vehicleId == preferredVehicleId,
          orElse: () => vehicles.first,
        );

  final location = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel('FINANÇAS'),
            _QuickAddTile(
              icon: Icons.swap_horiz_rounded,
              title: 'Nova transação',
              subtitle: 'Única, parcelada ou recorrente',
              onTap: () =>
                  Navigator.pop(sheetContext, '/finance/transactions/new'),
            ),
            if (vehicle != null) ...[
              const Divider(height: 24),
              _SectionLabel('VEÍCULO'),
              _QuickAddTile(
                icon: Icons.local_gas_station_rounded,
                title: 'Abastecimento',
                subtitle: 'Registre combustível e consumo',
                onTap: () => Navigator.pop(
                  sheetContext,
                  '/vehicles/${vehicle.vehicleId}/refuelings/new',
                ),
              ),
              _QuickAddTile(
                icon: Icons.build_circle_outlined,
                title: 'Manutenção',
                subtitle: 'Serviços, peças e revisões',
                onTap: () => Navigator.pop(
                  sheetContext,
                  '/vehicles/${vehicle.vehicleId}/maintenances/new',
                ),
              ),
              _QuickAddTile(
                icon: Icons.receipt_long_rounded,
                title: 'Despesa',
                subtitle: 'Outros gastos com o veículo',
                onTap: () => Navigator.pop(
                  sheetContext,
                  '/vehicles/${vehicle.vehicleId}/expenses/new',
                ),
              ),
              _QuickAddTile(
                icon: Icons.speed_rounded,
                title: 'Quilometragem',
                subtitle: 'Atualizar odômetro',
                onTap: () => Navigator.pop(
                  sheetContext,
                  '/vehicles/${vehicle.vehicleId}/edit',
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
  if (location != null && context.mounted) {
    await context.push(location);
    ref.read(dashboardProvider.notifier).reload();
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: context.colors.textSecondary,
        letterSpacing: 1.2,
      ),
    ),
  );
}

class _QuickAddTile extends StatelessWidget {
  const _QuickAddTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: context.colors.primary),
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );
}
