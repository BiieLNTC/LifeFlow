import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeflow_app/core/theme/app_palette.dart';
import 'package:lifeflow_app/features/history/domain/timeline_entry.dart';
import 'package:lifeflow_app/features/history/presentation/timeline_controller.dart';
import 'package:lifeflow_app/features/vehicles/presentation/vehicle_formatters.dart';

class TimelinePage extends ConsumerStatefulWidget {
  const TimelinePage({required this.vehicleId, super.key});
  final String vehicleId;

  @override
  ConsumerState<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends ConsumerState<TimelinePage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 400) {
      ref.read(timelineProvider(widget.vehicleId).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timelineProvider(widget.vehicleId));
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico')),
      body: SafeArea(
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _ErrorState(
            onRetry: () =>
                ref.read(timelineProvider(widget.vehicleId).notifier).reload(),
          ),
          data: (feed) {
            if (feed.items.isEmpty) return const _EmptyState();
            return RefreshIndicator(
              onRefresh: () => ref
                  .read(timelineProvider(widget.vehicleId).notifier)
                  .reload(),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                itemCount: feed.items.length + 1,
                itemBuilder: (context, index) {
                  if (index == feed.items.length) {
                    return _Footer(
                      feed: feed,
                      onRetry: () => ref
                          .read(timelineProvider(widget.vehicleId).notifier)
                          .loadMore(),
                    );
                  }
                  final entry = feed.items[index];
                  final previous = index == 0 ? null : feed.items[index - 1];
                  final beginsMonth =
                      previous == null ||
                      previous.date.month != entry.date.month ||
                      previous.date.year != entry.date.year;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (beginsMonth) _MonthHeader(date: entry.date),
                      _TimelineRow(
                        entry: entry,
                        onTap: () => _openEntry(entry),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void _openEntry(TimelineEntry entry) {
    final base = '/vehicles/${widget.vehicleId}';
    switch (entry.type) {
      case TimelineEventType.maintenance:
        context.push('$base/maintenances/${entry.id}');
        return;
      case TimelineEventType.refueling:
        context.push('$base/refuelings');
        return;
      case TimelineEventType.expense:
        context.push('$base/expenses');
        return;
    }
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.date});
  final DateTime date;

  static const months = [
    'JANEIRO',
    'FEVEREIRO',
    'MARÇO',
    'ABRIL',
    'MAIO',
    'JUNHO',
    'JULHO',
    'AGOSTO',
    'SETEMBRO',
    'OUTUBRO',
    'NOVEMBRO',
    'DEZEMBRO',
  ];

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 14),
    child: Text(
      '${months[date.month - 1]} ${date.year}',
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: context.colors.textSecondary,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
      ),
    ),
  );
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.entry, required this.onTap});
  final TimelineEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (entry.type) {
      TimelineEventType.refueling => (
        Icons.local_gas_station_rounded,
        context.colors.primary,
      ),
      TimelineEventType.maintenance => (
        Icons.build_circle_outlined,
        context.colors.warning,
      ),
      TimelineEventType.expense => (
        Icons.receipt_long_rounded,
        context.colors.textSecondary,
      ),
    };
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 38,
              child: Column(
                children: [
                  Text(
                    entry.date.day.toString().padLeft(2, '0'),
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    _weekday(entry.date),
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: context.colors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _details(entry),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              formatCurrency(entry.amount),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  String _details(TimelineEntry item) {
    final values = <String>[];
    if (item.odometer != null) values.add(formatOdometer(item.odometer!));
    final secondary = item.secondaryText?.trim();
    if (secondary != null && secondary.isNotEmpty) values.add(secondary);
    if (values.isEmpty) values.add(_category(item));
    return values.join(' • ');
  }

  String _category(TimelineEntry item) => switch (item.category) {
    'preventive' => 'Preventiva',
    'corrective' => 'Corretiva',
    'fuel' => 'Combustível',
    'insurance' => 'Seguro',
    'ipva' => 'IPVA',
    'licensing' => 'Licenciamento',
    'fine' => 'Multa',
    'toll' => 'Pedágio',
    'parking' => 'Estacionamento',
    'car_wash' => 'Lavagem',
    'accessories' => 'Acessórios',
    'tires' => 'Pneus',
    'maintenance' => 'Manutenção',
    'gasoline' => 'Gasolina',
    'ethanol' => 'Etanol',
    'flex' => 'Flex',
    'diesel' => 'Diesel',
    'electric' => 'Elétrico',
    'hybrid' => 'Híbrido',
    _ => 'Outros',
  };

  String _weekday(DateTime date) =>
      const ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM'][date.weekday - 1];
}

class _Footer extends StatelessWidget {
  const _Footer({required this.feed, required this.onRetry});
  final TimelineFeed feed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (feed.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (feed.loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Center(
          child: TextButton(
            onPressed: onRetry,
            child: const Text('TENTAR CARREGAR MAIS'),
          ),
        ),
      );
    }
    return const SizedBox(height: 20);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history_rounded,
            size: 60,
            color: context.colors.textSecondary,
          ),
          const SizedBox(height: 20),
          Text(
            'O histórico começa com o primeiro registro.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Abastecimentos, manutenções e despesas aparecerão aqui.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
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
          Icon(
            Icons.cloud_off_rounded,
            size: 52,
            color: context.colors.warning,
          ),
          const SizedBox(height: 20),
          Text(
            'Não foi possível carregar o histórico.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
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
