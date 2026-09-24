enum TimelineEventType {
  refueling('refueling'),
  maintenance('maintenance'),
  expense('expense');

  const TimelineEventType(this.databaseValue);
  final String databaseValue;

  static TimelineEventType fromDatabase(String value) =>
      values.firstWhere((item) => item.databaseValue == value);
}

class TimelineEntry {
  const TimelineEntry({
    required this.id,
    required this.vehicleId,
    required this.type,
    required this.date,
    required this.title,
    required this.amount,
    required this.createdAt,
    required this.category,
    this.secondaryText,
    this.odometer,
  });

  final String id;
  final String vehicleId;
  final TimelineEventType type;
  final DateTime date;
  final String title;
  final String? secondaryText;
  final String category;
  final int? odometer;
  final double amount;
  final DateTime createdAt;
}
