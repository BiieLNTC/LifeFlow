import 'package:lifeflow_app/features/history/domain/timeline_entry.dart';

abstract interface class TimelineRepository {
  Future<List<TimelineEntry>> getTimeline(
    String vehicleId, {
    required int offset,
    required int limit,
  });
}

class TimelineFailure implements Exception {
  const TimelineFailure(this.message);
  final String message;
}
