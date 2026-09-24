import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeflow_app/core/theme/app_palette.dart';
import 'package:lifeflow_app/features/refueling/domain/refueling.dart';
import 'package:lifeflow_app/features/refueling/presentation/refuelings_controller.dart';
import 'package:lifeflow_app/features/vehicles/presentation/vehicle_formatters.dart';

class RefuelingsPage extends ConsumerWidget {
  const RefuelingsPage({required this.vehicleId, super.key});
  final String vehicleId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(refuelingsProvider(vehicleId));
    return Scaffold(
      appBar: AppBar(title: const Text('Abastecimentos')),
      body: SafeArea(
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: OutlinedButton(
              onPressed: () =>
                  ref.read(refuelingsProvider(vehicleId).notifier).reload(),
              child: const Text('TENTAR NOVAMENTE'),
            ),
          ),
          data: (items) => items.isEmpty
              ? _Empty(
                  onCreate: () =>
                      context.push('/vehicles/$vehicleId/refuelings/new'),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(refuelingsProvider(vehicleId).notifier).reload(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 104),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _Tile(
                      item: items[i],
                      onEdit: () => context.push(
                        '/vehicles/$vehicleId/refuelings/${items[i].id}/edit',
                        extra: items[i],
                      ),
                      onDelete: () => _delete(context, ref, items[i]),
                    ),
                  ),
                ),
        ),
      ),
      floatingActionButton: state.value?.isNotEmpty == true
          ? FloatingActionButton.extended(
              onPressed: () =>
                  context.push('/vehicles/$vehicleId/refuelings/new'),
              icon: const Icon(Icons.add),
              label: const Text('ABASTECER'),
            )
          : null,
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Refueling item,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Remover abastecimento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('REMOVER'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(refuelingsProvider(vehicleId).notifier).delete(item.id);
    }
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });
  final Refueling item;
  final VoidCallback onEdit, onDelete;
  @override
  Widget build(BuildContext context) => Material(
    color: context.colors.surface,
    borderRadius: BorderRadius.circular(20),
    child: ListTile(
      contentPadding: const EdgeInsets.all(18),
      leading: Icon(
        Icons.local_gas_station_rounded,
        color: context.colors.primary,
      ),
      title: Text(
        formatCurrency(item.totalAmount),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${formatDate(item.date)} • ${item.liters.toStringAsFixed(2).replaceAll('.', ',')} L${item.consumptionKmL == null ? '' : ' • ${item.consumptionKmL!.toStringAsFixed(1).replaceAll('.', ',')} km/L'}',
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'edit', child: Text('Editar')),
          PopupMenuItem(value: 'delete', child: Text('Remover')),
        ],
      ),
    ),
  );
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
            Icons.local_gas_station_outlined,
            size: 60,
            color: context.colors.textSecondary,
          ),
          const SizedBox(height: 20),
          Text(
            'Nenhum abastecimento registrado.',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('REGISTRAR ABASTECIMENTO'),
          ),
        ],
      ),
    ),
  );
}
