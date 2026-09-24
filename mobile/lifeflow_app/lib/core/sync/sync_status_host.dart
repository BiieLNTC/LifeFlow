import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeflow_app/core/sync/sync_service.dart';
import 'package:lifeflow_app/core/theme/app_palette.dart';
import 'package:lifeflow_app/features/auth/domain/auth_repository.dart';
import 'package:lifeflow_app/features/auth/presentation/auth_controller.dart';
import 'package:lifeflow_app/features/dashboard/presentation/dashboard_controller.dart';
import 'package:lifeflow_app/features/expenses/presentation/expenses_controller.dart';
import 'package:lifeflow_app/features/finance/presentation/budgets_controller.dart';
import 'package:lifeflow_app/features/finance/presentation/categories_controller.dart';
import 'package:lifeflow_app/features/finance/presentation/people_controller.dart';
import 'package:lifeflow_app/features/finance/presentation/recurring_transactions_controller.dart';
import 'package:lifeflow_app/features/finance/presentation/savings_goals_controller.dart';
import 'package:lifeflow_app/features/finance/presentation/transactions_controller.dart';
import 'package:lifeflow_app/features/history/presentation/timeline_controller.dart';
import 'package:lifeflow_app/features/maintenance/presentation/maintenance_controller.dart';
import 'package:lifeflow_app/features/refueling/presentation/refuelings_controller.dart';
import 'package:lifeflow_app/features/reminders/presentation/reminders_controller.dart';
import 'package:lifeflow_app/features/vehicles/presentation/vehicles_controller.dart';

class SyncStatusHost extends ConsumerStatefulWidget {
  const SyncStatusHost({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<SyncStatusHost> createState() => _SyncStatusHostState();
}

class _SyncStatusHostState extends ConsumerState<SyncStatusHost>
    with WidgetsBindingObserver {
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _sync();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authSessionProvider, (previous, next) {
      final wasAuthenticated = previous?.value?.isAuthenticated ?? false;
      final isAuthenticated = next.value?.isAuthenticated ?? false;
      if (!wasAuthenticated && isAuthenticated) _sync();
    });
    final summary = ref.watch(syncSummaryProvider).value;
    if (summary == null || !summary.hasIssues) return widget.child;

    final hasFailure = summary.failed > 0;
    final message = hasFailure
        ? '${summary.failed} altera\u00e7\u00e3o(\u00f5es) precisam de revis\u00e3o'
        : '${summary.pending} altera\u00e7\u00e3o(\u00f5es) aguardando conex\u00e3o';
    return Stack(
      children: [
        widget.child,
        Positioned(
          left: 16,
          right: 16,
          bottom: 92,
          child: SafeArea(
            top: false,
            child: Material(
              color: hasFailure ? context.colors.critical : context.colors.surface,
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              child: Semantics(
                liveRegion: true,
                label: message,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                  child: Row(
                    children: [
                      Icon(
                        hasFailure ? Icons.sync_problem : Icons.cloud_off,
                        color: hasFailure
                            ? context.colors.textPrimary
                            : context.colors.warning,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          message,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        tooltip: hasFailure
                            ? 'Tentar sincronizar novamente'
                            : 'Sincronizar agora',
                        onPressed: _syncing
                            ? null
                            : () => _sync(retryFailed: hasFailure),
                        icon: _syncing
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.sync),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _sync({bool retryFailed = false}) async {
    if (_syncing || !mounted) return;
    final auth = ref.read(authSessionProvider).value;
    if (auth?.status == AuthSessionStatus.signedOut) return;
    setState(() => _syncing = true);
    try {
      await ref.read(syncRunnerProvider)(retryFailed: retryFailed);
      if (!mounted) return;
      ref
        ..invalidate(vehiclesControllerProvider)
        ..invalidate(vehicleDetailsProvider)
        ..invalidate(maintenancesProvider)
        ..invalidate(maintenanceDetailsProvider)
        ..invalidate(refuelingsProvider)
        ..invalidate(expensesProvider)
        ..invalidate(expenseDetailsProvider)
        ..invalidate(remindersProvider)
        ..invalidate(reminderDetailsProvider)
        ..invalidate(dashboardProvider)
        ..invalidate(timelineProvider)
        ..invalidate(categoriesControllerProvider)
        ..invalidate(peopleControllerProvider)
        ..invalidate(transactionsControllerProvider)
        ..invalidate(budgetsControllerProvider)
        ..invalidate(recurringTransactionsControllerProvider)
        ..invalidate(savingsGoalsControllerProvider);
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }
}
