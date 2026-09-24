import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeflow_app/core/navigation/app_bottom_nav.dart';
import 'package:lifeflow_app/core/navigation/app_tab.dart';
import 'package:lifeflow_app/core/theme/app_palette.dart';
import 'package:lifeflow_app/features/finance/domain/finance_summary.dart';
import 'package:lifeflow_app/features/finance/domain/savings_goal.dart';
import 'package:lifeflow_app/features/finance/domain/transaction.dart';
import 'package:lifeflow_app/features/finance/presentation/finance_summary_controller.dart';
import 'package:lifeflow_app/features/finance/presentation/recurring_transactions_controller.dart';
import 'package:lifeflow_app/features/finance/presentation/savings_goals_controller.dart';
import 'package:lifeflow_app/features/finance/presentation/transactions_controller.dart';
import 'package:lifeflow_app/features/notifications/presentation/notification_bell.dart';
import 'package:lifeflow_app/features/vehicles/presentation/vehicle_formatters.dart';

class FinancePage extends ConsumerStatefulWidget {
  const FinancePage({super.key});

  @override
  ConsumerState<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends ConsumerState<FinancePage> {
  @override
  void initState() {
    super.initState();
    // Gera ocorrências de recorrência pendentes ao abrir a tela de finanças
    // (nunca por cron — ver ROADMAP.md §1.5).
    WidgetsBinding.instance.addPostFrameCallback((_) => _generateDueOccurrences());
  }

  Future<void> _generateDueOccurrences() async {
    final generated = await ref
        .read(recurringTransactionsControllerProvider.notifier)
        .generateDueOccurrences();
    if (generated > 0 && mounted) {
      ref
        ..invalidate(financeTotalsProvider)
        ..invalidate(budgetProgressProvider);
      await ref.read(transactionsControllerProvider.notifier).reload();
    }
  }

  Future<void> _reload() async {
    ref
      ..invalidate(financeTotalsProvider)
      ..invalidate(budgetProgressProvider);
    await ref.read(transactionsControllerProvider.notifier).reload();
  }

  @override
  Widget build(BuildContext context) {
    final totals = ref.watch(financeTotalsProvider);
    final budgetProgress = ref.watch(budgetProgressProvider);
    final transactions = ref.watch(transactionsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'FINANÇAS',
          style: TextStyle(
            color: context.colors.primary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
          ),
        ),
        actions: [
          const NotificationBell(),
          IconButton(
            tooltip: 'Metas de poupança',
            onPressed: () => context.push('/finance/goals'),
            icon: const Icon(Icons.savings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 104),
            children: [
              totals.when(
                loading: () => const _BalanceCardLoading(),
                error: (_, _) => const _BalanceCardError(),
                data: (value) => _BalanceCard(totals: value),
              ),
              const SizedBox(height: 28),
              Text('ORÇAMENTOS DO MÊS', style: _sectionStyle(context)),
              const SizedBox(height: 14),
              budgetProgress.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, _) => Text(
                  'Não foi possível carregar os orçamentos.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                data: (items) => items.isEmpty
                    ? Text(
                        'Nenhum orçamento definido para este mês.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      )
                    : Column(
                        children: [
                          for (final budget in items) ...[
                            _BudgetTile(progress: budget),
                            const SizedBox(height: 10),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('META', style: _sectionStyle(context)),
                  TextButton(
                    onPressed: () => context.push('/finance/goals'),
                    child: const Text('VER TODAS'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const _FeaturedGoal(),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('TRANSAÇÕES RECENTES', style: _sectionStyle(context)),
                  TextButton(
                    onPressed: () => context.push('/finance/transactions/new'),
                    child: const Text('NOVA'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              transactions.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, _) => Text(
                  'Não foi possível carregar as transações.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                data: (items) => items.isEmpty
                    ? _EmptyTransactions(
                        onCreate: () =>
                            context.push('/finance/transactions/new'),
                      )
                    : Column(
                        children: [
                          for (final transaction in items.take(20)) ...[
                            _TransactionTile(transaction: transaction),
                            const SizedBox(height: 10),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentTab: AppTab.finance),
    );
  }

  TextStyle? _sectionStyle(BuildContext context) =>
      Theme.of(context).textTheme.labelLarge?.copyWith(
        color: context.colors.textSecondary,
        letterSpacing: 1.4,
      );
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.totals});
  final FinanceTotals totals;

  @override
  Widget build(BuildContext context) => Material(
    color: context.colors.surface,
    borderRadius: BorderRadius.circular(28),
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SALDO',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: context.colors.textSecondary,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            formatCurrency(totals.balance),
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  icon: Icons.arrow_upward_rounded,
                  color: context.colors.primary,
                  label: 'receitas do mês',
                  value: formatCurrency(totals.monthlyIncome),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniMetric(
                  icon: Icons.arrow_downward_rounded,
                  color: context.colors.critical,
                  label: 'despesas do mês',
                  value: formatCurrency(totals.monthlyExpense),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      const SizedBox(height: 2),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _BalanceCardLoading extends StatelessWidget {
  const _BalanceCardLoading();

  @override
  Widget build(BuildContext context) => Material(
    color: context.colors.surface,
    borderRadius: BorderRadius.circular(28),
    child: const Padding(
      padding: EdgeInsets.all(40),
      child: Center(child: CircularProgressIndicator()),
    ),
  );
}

class _BalanceCardError extends StatelessWidget {
  const _BalanceCardError();

  @override
  Widget build(BuildContext context) => Material(
    color: context.colors.surface,
    borderRadius: BorderRadius.circular(28),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, color: context.colors.warning),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Não foi possível carregar seu saldo.'),
          ),
        ],
      ),
    ),
  );
}

class _BudgetTile extends StatelessWidget {
  const _BudgetTile({required this.progress});
  final BudgetProgress progress;

  @override
  Widget build(BuildContext context) {
    final color = switch (progress.status) {
      BudgetStatus.critical => context.colors.critical,
      BudgetStatus.warning => context.colors.warning,
      BudgetStatus.normal => context.colors.primary,
    };
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  progress.categoryDescription,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${formatCurrency(progress.spentAmount)} / ${formatCurrency(progress.limitAmount)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (progress.percentage ?? 0) / 100,
                minHeight: 8,
                backgroundColor: context.colors.background,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});
  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? context.colors.primary : context.colors.critical;
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        leading: Icon(
          isIncome ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
          color: color,
        ),
        title: Text(transaction.description),
        subtitle: Text(
          formatDate(transaction.transactionDate) +
              (transaction.installmentTotal == null
                  ? ''
                  : ' • parcela ${transaction.installmentIndex}/${transaction.installmentTotal}'),
        ),
        trailing: Text(
          formatCurrency(transaction.amount),
          style: TextStyle(fontWeight: FontWeight.w700, color: color),
        ),
        enabled: transaction.isEditable,
        onTap: transaction.isEditable
            ? () => context.push('/finance/transactions/${transaction.id}/edit')
            : null,
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text(
            'Nenhuma transação registrada ainda.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('NOVA TRANSAÇÃO'),
          ),
        ],
      ),
    ),
  );
}

class _FeaturedGoal extends ConsumerWidget {
  const _FeaturedGoal();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(savingsGoalsControllerProvider);
    return goals.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Text(
        'Não foi possível carregar suas metas.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      data: (items) => items.isEmpty
          ? _EmptyGoal(onCreate: () => context.push('/finance/goals/new'))
          : _GoalProgressCard(goal: items.first),
    );
  }
}

class _GoalProgressCard extends ConsumerWidget {
  const _GoalProgressCard({required this.goal});
  final SavingsGoal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contributions = ref.watch(goalContributionsProvider(goal.id));
    final saved =
        contributions.value?.fold<double>(0, (sum, c) => sum + c.amount) ?? 0;
    final progress = goal.targetAmount == 0
        ? 0.0
        : (saved / goal.targetAmount).clamp(0, 1).toDouble();
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/finance/goals/${goal.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(goal.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(
                    '${formatCurrency(saved)} / ${formatCurrency(goal.targetAmount)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: context.colors.background,
                  color: context.colors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyGoal extends StatelessWidget {
  const _EmptyGoal({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          'Nenhuma meta cadastrada ainda.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
      TextButton(onPressed: onCreate, child: const Text('CRIAR META')),
    ],
  );
}
