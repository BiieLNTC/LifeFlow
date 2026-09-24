import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeflow_app/core/theme/app_palette.dart';
import 'package:lifeflow_app/features/finance/domain/recurring_transaction.dart';
import 'package:lifeflow_app/features/finance/domain/recurring_transaction_repository.dart';
import 'package:lifeflow_app/features/finance/domain/transaction.dart';
import 'package:lifeflow_app/features/finance/presentation/recurring_transactions_controller.dart';
import 'package:lifeflow_app/features/finance/presentation/transactions_controller.dart';
import 'package:lifeflow_app/features/vehicles/presentation/vehicle_formatters.dart';

class RecurringTransactionsPage extends ConsumerStatefulWidget {
  const RecurringTransactionsPage({super.key});

  @override
  ConsumerState<RecurringTransactionsPage> createState() => _State();
}

class _State extends ConsumerState<RecurringTransactionsPage> {
  bool _generating = false;

  Future<void> _generateDue() async {
    setState(() => _generating = true);
    try {
      final generated = await ref
          .read(recurringTransactionsControllerProvider.notifier)
          .generateDueOccurrences();
      ref.invalidate(transactionsControllerProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              generated == 0
                  ? 'Nenhuma ocorrência pendente.'
                  : '$generated transação(ões) gerada(s).',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recurring = ref.watch(recurringTransactionsControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transações recorrentes'),
        actions: [
          IconButton(
            tooltip: 'Gerar ocorrências pendentes',
            onPressed: _generating ? null : _generateDue,
            icon: _generating
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.autorenew_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: recurring.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _ErrorState(
            onRetry: () => ref
                .read(recurringTransactionsControllerProvider.notifier)
                .reload(),
          ),
          data: (items) => items.isEmpty
              ? _EmptyState(onCreate: () => context.push('/more/recurring/new'))
              : RefreshIndicator(
                  onRefresh: () => ref
                      .read(recurringTransactionsControllerProvider.notifier)
                      .reload(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    children: [
                      for (final item in items) ...[
                        _RecurringTile(item: item),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/more/recurring/new'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('RECORRÊNCIA'),
      ),
    );
  }
}

class _RecurringTile extends ConsumerWidget {
  const _RecurringTile({required this.item});
  final RecurringTransaction item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = item.type == TransactionType.income
        ? context.colors.primary
        : context.colors.critical;
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        leading: Icon(
          item.type == TransactionType.income
              ? Icons.arrow_upward_rounded
              : Icons.arrow_downward_rounded,
          color: color,
        ),
        title: Text(item.description),
        subtitle: Text(
          'Dia ${item.dayOfMonth} • ${formatCurrency(item.amount)}'
          '${item.paused ? ' • Pausada' : ''}',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) async {
            if (action == 'edit') {
              context.push('/more/recurring/${item.id}/edit');
            } else if (action == 'delete') {
              await _delete(context, ref);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Editar')),
            PopupMenuItem(value: 'delete', child: Text('Remover')),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remover recorrência?'),
        content: Text(
          '${item.description} deixará de gerar novas transações.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'REMOVER',
              style: TextStyle(color: dialogContext.colors.critical),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(recurringTransactionsControllerProvider.notifier)
          .delete(item.id);
    } on RecurringTransactionFailure catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.autorenew_rounded,
            size: 60,
            color: context.colors.textSecondary,
          ),
          const SizedBox(height: 20),
          Text(
            'Nenhuma recorrência cadastrada.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          Text(
            'Assinaturas, salário e outras transações mensais podem ser automatizadas aqui.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('NOVA RECORRÊNCIA'),
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
          Icon(Icons.cloud_off_rounded, size: 52, color: context.colors.warning),
          const SizedBox(height: 16),
          const Text('Não foi possível carregar as recorrências.'),
          const SizedBox(height: 20),
          OutlinedButton(onPressed: onRetry, child: const Text('TENTAR NOVAMENTE')),
        ],
      ),
    ),
  );
}
