import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeflow_app/core/theme/app_palette.dart';
import 'package:lifeflow_app/features/finance/domain/savings_goal.dart';
import 'package:lifeflow_app/features/finance/presentation/savings_goals_controller.dart';
import 'package:lifeflow_app/features/vehicles/presentation/vehicle_formatters.dart';

class SavingsGoalsPage extends ConsumerWidget {
  const SavingsGoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(savingsGoalsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Metas de poupança')),
      body: SafeArea(
        child: goals.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _ErrorState(
            onRetry: () =>
                ref.read(savingsGoalsControllerProvider.notifier).reload(),
          ),
          data: (items) => items.isEmpty
              ? _EmptyState(onCreate: () => context.push('/finance/goals/new'))
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(savingsGoalsControllerProvider.notifier).reload(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    children: [
                      for (final goal in items) ...[
                        _GoalTile(goal: goal),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/finance/goals/new'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('META'),
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({required this.goal});
  final SavingsGoal goal;

  @override
  Widget build(BuildContext context) => Material(
    color: context.colors.surface,
    borderRadius: BorderRadius.circular(16),
    child: ListTile(
      leading: Icon(Icons.savings_outlined, color: context.colors.primary),
      title: Text(goal.title),
      subtitle: Text(
        'Meta de ${formatCurrency(goal.targetAmount)}'
        '${goal.targetDate == null ? '' : ' até ${formatDate(goal.targetDate!)}'}',
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => context.push('/finance/goals/${goal.id}'),
    ),
  );
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
          Icon(Icons.savings_outlined, size: 60, color: context.colors.textSecondary),
          const SizedBox(height: 20),
          Text(
            'Nenhuma meta cadastrada.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          Text(
            'Defina um valor e acompanhe seus aportes até chegar lá.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('NOVA META'),
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
          const Text('Não foi possível carregar suas metas.'),
          const SizedBox(height: 20),
          OutlinedButton(onPressed: onRetry, child: const Text('TENTAR NOVAMENTE')),
        ],
      ),
    ),
  );
}
