import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeflow_app/core/navigation/app_bottom_nav.dart';
import 'package:lifeflow_app/core/navigation/app_tab.dart';
import 'package:lifeflow_app/core/theme/app_palette.dart';
import 'package:lifeflow_app/features/auth/presentation/auth_controller.dart';
import 'package:lifeflow_app/features/dashboard/domain/vehicle_dashboard.dart';
import 'package:lifeflow_app/features/dashboard/presentation/dashboard_controller.dart';
import 'package:lifeflow_app/features/finance/domain/finance_summary.dart';
import 'package:lifeflow_app/features/finance/presentation/finance_summary_controller.dart';
import 'package:lifeflow_app/features/notifications/presentation/notification_bell.dart';
import 'package:lifeflow_app/features/notifications/presentation/notifications_controller.dart';
import 'package:lifeflow_app/features/reminders/domain/reminder.dart';
import 'package:lifeflow_app/features/vehicles/domain/vehicle.dart';
import 'package:lifeflow_app/features/vehicles/presentation/vehicle_formatters.dart';
import 'package:lifeflow_app/core/widgets/lifeflow_wordmark.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String? _selectedVehicleId;

  Future<void> _open(String location) async {
    await context.push(location);
    if (mounted) {
      ref.invalidate(notificationsProvider);
      await ref.read(dashboardProvider.notifier).reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(dashboardProvider);
    final session = ref.watch(authSessionProvider).value;
    return Scaffold(
      appBar: AppBar(
        title: const LifeFlowWordmark(height: 14),
        actions: const [NotificationBell()],
      ),
      body: SafeArea(
        child: dashboard.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _DashboardError(
            onRetry: () => ref.read(dashboardProvider.notifier).reload(),
          ),
          data: (vehicles) {
            if (vehicles.isEmpty) {
              return _EmptyHome(onCreate: () => _open('/vehicles/new'));
            }
            final selected = vehicles.firstWhere(
              (item) => item.vehicleId == _selectedVehicleId,
              orElse: () => vehicles.first,
            );
            return RefreshIndicator(
              onRefresh: () => ref.read(dashboardProvider.notifier).reload(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  Text(
                    '${_greeting()}, ${_firstName(session?.name, session?.email)}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 20),
                  const _FinanceSnippet(),
                  const SizedBox(height: 24),
                  if (vehicles.length > 1) ...[
                    SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: vehicles.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final vehicle = vehicles[index];
                          return ChoiceChip(
                            label: Text(vehicle.nickname),
                            selected: vehicle.vehicleId == selected.vehicleId,
                            onSelected: (_) => setState(
                              () => _selectedVehicleId = vehicle.vehicleId,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  _VehicleHero(
                    vehicle: selected,
                    onTap: () => _open('/vehicles/${selected.vehicleId}'),
                  ),
                  const SizedBox(height: 28),
                  _CareSection(
                    vehicle: selected,
                    onTap: () =>
                        _open('/vehicles/${selected.vehicleId}/reminders'),
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () =>
                          _open('/vehicles/${selected.vehicleId}/history'),
                      icon: const Icon(Icons.history_rounded),
                      label: const Text('VER HISTÓRICO'),
                    ),
                  ),
                  const _BudgetsOfMonthSection(),
                  const SizedBox(height: 30),
                  Text(
                    'ESTE MÊS',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: context.colors.textSecondary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _Metric(
                          value: formatCurrency(selected.monthlySpending),
                          label: 'gastos',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _Metric(
                          value: selected.monthlyConsumptionKmL == null
                              ? '—'
                              : '${selected.monthlyConsumptionKmL!.toStringAsFixed(1).replaceAll('.', ',')} km/L',
                          label: 'consumo',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _Metric(
                          value: selected.costPerKm == null
                              ? '—'
                              : '${formatCurrency(selected.costPerKm!)}/km',
                          label: 'custo',
                        ),
                      ),
                    ],
                  ),
                  if (selected.monthlyConsumptionKmL == null ||
                      selected.costPerKm == null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Consumo e custo/km aparecem quando há registros suficientes no mês.',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: context.colors.textSecondary),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentTab: AppTab.home,
        preferredVehicleId: _selectedVehicleId,
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  String _firstName(String? name, String? email) {
    final normalized = name?.trim();
    if (normalized != null && normalized.isNotEmpty) {
      return normalized.split(RegExp(r'\s+')).first;
    }
    final emailName = email?.split('@').first.trim();
    return emailName == null || emailName.isEmpty ? 'motorista' : emailName;
  }
}

class _VehicleHero extends StatelessWidget {
  const _VehicleHero({required this.vehicle, required this.onTap});
  final VehicleDashboard vehicle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: context.colors.surface,
    borderRadius: BorderRadius.circular(28),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SEU VEÍCULO',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: context.colors.textSecondary,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        vehicle.nickname,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _description(vehicle),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Icon(
                  vehicle.vehicleType == VehicleType.car
                      ? Icons.directions_car_filled_rounded
                      : Icons.two_wheeler_rounded,
                  size: 62,
                  color: context.colors.primary,
                ),
              ],
            ),
            const SizedBox(height: 26),
            Text(
              formatOdometer(vehicle.currentOdometer),
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    ),
  );

  String _description(VehicleDashboard item) {
    final year = item.modelYear ?? item.manufactureYear;
    return year == null ? item.description : '${item.description} • $year';
  }
}

class _CareSection extends StatelessWidget {
  const _CareSection({required this.vehicle, required this.onTap});
  final VehicleDashboard vehicle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reminder = vehicle.nextReminder;
    final urgency = reminder?.urgency;
    final color = switch (urgency) {
      ReminderUrgency.overdue => context.colors.critical,
      ReminderUrgency.near => context.colors.warning,
      _ => context.colors.primary,
    };
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                reminder == null
                    ? Icons.check_rounded
                    : Icons.notifications_active_outlined,
                color: color,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder == null ? 'Tudo em dia' : 'Próximo cuidado',
                    style: TextStyle(color: color, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    reminder == null
                        ? 'Nenhum lembrete pendente'
                        : reminder.description,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (reminder != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      _remaining(reminder),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }

  String _remaining(DashboardReminder reminder) {
    if (reminder.urgency == ReminderUrgency.overdue) return 'Vencido';
    final values = <String>[];
    if (reminder.remainingKm != null) {
      values.add('faltam ${formatOdometer(reminder.remainingKm!)}');
    }
    if (reminder.remainingDays != null) {
      values.add('faltam ${reminder.remainingDays} dias');
    }
    return values.isEmpty ? reminder.urgency.label : values.join(' • ');
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 3),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _EmptyHome extends StatelessWidget {
  const _EmptyHome({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _FinanceSnippet(),
          const SizedBox(height: 32),
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
            'Cadastre seu primeiro veículo para começar a cuidar dele.',
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

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.onRetry});
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
          const SizedBox(height: 20),
          Text(
            'Não foi possível carregar sua Home.',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Confira sua conexão e tente novamente.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
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

class _FinanceSnippet extends ConsumerWidget {
  const _FinanceSnippet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(financeTotalsProvider);
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/finance'),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: context.colors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SALDO',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: context.colors.textSecondary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      totals.when(
                        data: (value) => formatCurrency(value.balance),
                        loading: () => '—',
                        error: (_, _) => '—',
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w800),
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

class _BudgetsOfMonthSection extends ConsumerWidget {
  const _BudgetsOfMonthSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(budgetProgressProvider);
    final items = budgets.value ?? const <BudgetProgress>[];
    if (items.isEmpty) return const SizedBox.shrink();

    final attention = [...items]
      ..sort((a, b) => (b.percentage ?? 0).compareTo(a.percentage ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ORÇAMENTOS DO MÊS',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: context.colors.textSecondary,
                letterSpacing: 1.5,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/finance'),
              child: const Text('VER TODOS'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final budget in attention.take(3)) ...[
          _BudgetLine(budget: budget),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _BudgetLine extends StatelessWidget {
  const _BudgetLine({required this.budget});
  final BudgetProgress budget;

  @override
  Widget build(BuildContext context) {
    final color = switch (budget.status) {
      BudgetStatus.critical => context.colors.critical,
      BudgetStatus.warning => context.colors.warning,
      BudgetStatus.normal => context.colors.primary,
    };
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(budget.categoryDescription),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (budget.percentage ?? 0) / 100,
                  minHeight: 6,
                  backgroundColor: context.colors.surface,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${(budget.percentage ?? 0).toStringAsFixed(0)}%',
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
