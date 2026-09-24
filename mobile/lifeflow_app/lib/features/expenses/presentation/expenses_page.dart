import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeflow_app/core/theme/app_palette.dart';
import 'package:lifeflow_app/features/expenses/domain/expense.dart';
import 'package:lifeflow_app/features/expenses/presentation/expenses_controller.dart';
import 'package:lifeflow_app/features/vehicles/presentation/vehicle_formatters.dart';

class ExpensesPage extends ConsumerWidget {
  const ExpensesPage({required this.vehicleId, super.key});
  final String vehicleId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(expensesProvider(vehicleId));
    return Scaffold(
      appBar: AppBar(title: const Text('Despesas')),
      body: SafeArea(
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: OutlinedButton(
              onPressed: () =>
                  ref.read(expensesProvider(vehicleId).notifier).reload(),
              child: const Text('TENTAR NOVAMENTE'),
            ),
          ),
          data: (items) => items.isEmpty
              ? _Empty(
                  onCreate: () =>
                      context.push('/vehicles/$vehicleId/expenses/new'),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(expensesProvider(vehicleId).notifier).reload(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 104),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _Tile(
                      item: items[i],
                      onEdit: () => context.push(
                        '/vehicles/$vehicleId/expenses/${items[i].id}/edit',
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
                  context.push('/vehicles/$vehicleId/expenses/new'),
              icon: const Icon(Icons.add),
              label: const Text('DESPESA'),
            )
          : null,
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Expense item,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Remover despesa?'),
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
      await ref.read(expensesProvider(vehicleId).notifier).delete(item.id);
    }
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });
  final Expense item;
  final VoidCallback onEdit, onDelete;
  @override
  Widget build(BuildContext context) => Material(
    color: context.colors.surface,
    borderRadius: BorderRadius.circular(20),
    child: ListTile(
      contentPadding: const EdgeInsets.all(18),
      leading: Icon(Icons.receipt_long_rounded, color: context.colors.primary),
      title: Text(
        item.description,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text('${item.category.label} • ${formatDate(item.date)}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatCurrency(item.amount),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          PopupMenuButton<String>(
            onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Editar')),
              PopupMenuItem(value: 'delete', child: Text('Remover')),
            ],
          ),
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
            Icons.receipt_long_outlined,
            size: 60,
            color: context.colors.textSecondary,
          ),
          const SizedBox(height: 20),
          Text(
            'Nenhuma despesa registrada.',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Registre seguro, IPVA, pedágio e outros custos.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('NOVA DESPESA'),
          ),
        ],
      ),
    ),
  );
}
