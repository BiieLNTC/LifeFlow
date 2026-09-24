import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeflow_app/features/history/data/supabase_timeline_repository.dart';
import 'package:lifeflow_app/features/history/domain/timeline_entry.dart';
import 'package:lifeflow_app/features/history/domain/timeline_repository.dart';
import 'package:lifeflow_app/features/history/presentation/timeline_controller.dart';

void main() {
  test('carrega a timeline em páginas sem duplicar registros', () async {
    final repository = _FakeTimelineRepository(
      List.generate(31, _entry),
    );
    final container = ProviderContainer(
      overrides: [timelineRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      timelineProvider('vehicle-id'),
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    final first = await container.read(timelineProvider('vehicle-id').future);
    expect(first.items, hasLength(30));
    expect(first.hasMore, isTrue);

    await container.read(timelineProvider('vehicle-id').notifier).loadMore();
    final completed = container.read(timelineProvider('vehicle-id')).value!;
    expect(completed.items, hasLength(31));
    expect(completed.hasMore, isFalse);
    expect(completed.items.map((item) => item.id).toSet(), hasLength(31));
  });
}

TimelineEntry _entry(int index) => TimelineEntry(
  id: 'entry-$index',
  vehicleId: 'vehicle-id',
  type: TimelineEventType.expense,
  date: DateTime.utc(2026, 9, 20).subtract(Duration(days: index)),
  title: 'Despesa $index',
  category: 'other',
  amount: index.toDouble(),
  createdAt: DateTime.utc(2026, 9, 20).subtract(Duration(days: index)),
);

class _FakeTimelineRepository implements TimelineRepository {
  _FakeTimelineRepository(this.items);
  final List<TimelineEntry> items;

  @override
  Future<List<TimelineEntry>> getTimeline(
    String vehicleId, {
    required int offset,
    required int limit,
  }) async => items.skip(offset).take(limit).toList();
}
