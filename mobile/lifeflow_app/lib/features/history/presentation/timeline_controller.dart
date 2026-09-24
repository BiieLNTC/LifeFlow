import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeflow_app/features/history/data/supabase_timeline_repository.dart';
import 'package:lifeflow_app/features/history/domain/timeline_entry.dart';
import 'package:lifeflow_app/features/history/domain/timeline_repository.dart';

class TimelineFeed {
  const TimelineFeed({
    required this.items,
    required this.hasMore,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  final List<TimelineEntry> items;
  final bool hasMore;
  final bool isLoadingMore;
  final String? loadMoreError;

  TimelineFeed copyWith({
    List<TimelineEntry>? items,
    bool? hasMore,
    bool? isLoadingMore,
    String? loadMoreError,
    bool clearError = false,
  }) => TimelineFeed(
    items: items ?? this.items,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreError: clearError ? null : loadMoreError ?? this.loadMoreError,
  );
}

final timelineProvider =
    AsyncNotifierProvider.family<TimelineController, TimelineFeed, String>(
      TimelineController.new,
    );

class TimelineController extends AsyncNotifier<TimelineFeed> {
  TimelineController(this.vehicleId);
  final String vehicleId;
  static const pageSize = 30;

  @override
  Future<TimelineFeed> build() async {
    final repository = ref.watch(timelineRepositoryProvider);
    final items = await _firstPage(repository);
    return TimelineFeed(items: items, hasMore: items.length == pageSize);
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final items = await _firstPage(ref.read(timelineRepositoryProvider));
      return TimelineFeed(items: items, hasMore: items.length == pageSize);
    });
  }

  Future<void> loadMore() async {
    final feed = state.value;
    if (feed == null || !feed.hasMore || feed.isLoadingMore) return;
    state = AsyncData(feed.copyWith(isLoadingMore: true, clearError: true));
    try {
      final next = await ref
          .read(timelineRepositoryProvider)
          .getTimeline(vehicleId, offset: feed.items.length, limit: pageSize);
      state = AsyncData(
        TimelineFeed(
          items: [...feed.items, ...next],
          hasMore: next.length == pageSize,
        ),
      );
    } on TimelineFailure catch (failure) {
      state = AsyncData(
        feed.copyWith(isLoadingMore: false, loadMoreError: failure.message),
      );
    }
  }

  Future<List<TimelineEntry>> _firstPage(TimelineRepository repository) =>
      repository.getTimeline(vehicleId, offset: 0, limit: pageSize);
}
