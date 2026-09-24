import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeflow_app/core/theme/app_palette.dart';
import 'package:lifeflow_app/features/finance/domain/savings_goal.dart';
import 'package:lifeflow_app/features/finance/presentation/savings_goals_controller.dart';
import 'package:lifeflow_app/features/vehicles/presentation/vehicle_formatters.dart';

class SavingsGoalDetailsPage extends ConsumerStatefulWidget {
  const SavingsGoalDetailsPage({required this.goalId, super.key});
  final String goalId;

  @override
  ConsumerState<SavingsGoalDetailsPage> createState() => _State();
}

class _State extends ConsumerState<SavingsGoalDetailsPage> {
  Future<void> _addContribution(SavingsGoal goal) async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Novo aporte'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Valor', prefixText: 'R\$ '),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              final value = double.tryParse(
                text.contains(',') ? text.replaceAll('.', '').replaceAll(',', '.') : text,
              );
              Navigator.pop(dialogContext, value);
            },
            child: const Text('ADICIONAR'),
          ),
        ],
      ),
    );
    if (amount == null || amount <= 0 || !mounted) return;
    await ref
        .read(goalContributionsProvider(widget.goalId).notifier)
        .add(
          GoalContributionDraft(
            goalId: widget.goalId,
            amount: amount,
            contributionDate: DateTime.now(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final goal = ref.watch(savingsGoalDetailsProvider(widget.goalId));
    final contributions = ref.watch(goalContributionsProvider(widget.goalId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meta'),
        actions: [
          if (goal.value != null)
            IconButton(
              tooltip: 'Editar',
              onPressed: () =>
                  context.push('/finance/goals/${widget.goalId}/edit'),
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: SafeArea(
        child: goal.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Center(child: Text('Meta indisponível.')),
          data: (item) {
            final saved = contributions.value?.fold<double>(
              0,
              (sum, c) => sum + c.amount,
            ) ?? 0;
            final progress = item.targetAmount == 0
                ? 0.0
                : (saved / item.targetAmount).clamp(0, 1).toDouble();
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              children: [
                Text(item.title, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 6),
                Text(
                  'Meta de ${formatCurrency(item.targetAmount)}'
                  '${item.targetDate == null ? '' : ' até ${formatDate(item.targetDate!)}'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: context.colors.surface,
                    color: context.colors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${formatCurrency(saved)} guardados • ${(progress * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Aportes', style: Theme.of(context).textTheme.titleLarge),
                    TextButton.icon(
                      onPressed: () => _addContribution(item),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('APORTE'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                contributions.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, _) => const Text('Não foi possível carregar os aportes.'),
                  data: (items) => items.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'Nenhum aporte registrado ainda.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        )
                      : Column(
                          children: [
                            for (final contribution in items) ...[
                              Material(
                                color: context.colors.surface,
                                borderRadius: BorderRadius.circular(16),
                                child: ListTile(
                                  leading: Icon(
                                    Icons.savings_outlined,
                                    color: context.colors.primary,
                                  ),
                                  title: Text(formatCurrency(contribution.amount)),
                                  subtitle: Text(formatDate(contribution.contributionDate)),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded),
                                    onPressed: () => ref
                                        .read(
                                          goalContributionsProvider(
                                            widget.goalId,
                                          ).notifier,
                                        )
                                        .delete(contribution.id),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
