enum ReminderStatus {
  active('active'),
  completed('completed');

  const ReminderStatus(this.databaseValue);
  final String databaseValue;

  static ReminderStatus fromDatabase(String value) =>
      values.firstWhere((item) => item.databaseValue == value);
}

enum ReminderUrgency {
  upcoming('upcoming', 'Em dia'),
  near('near', 'Próximo'),
  overdue('overdue', 'Vencido'),
  completed('completed', 'Concluído');

  const ReminderUrgency(this.databaseValue, this.label);
  final String databaseValue;
  final String label;

  static ReminderUrgency fromDatabase(String value) =>
      values.firstWhere((item) => item.databaseValue == value);
}

class Reminder {
  const Reminder({
    required this.id,
    required this.vehicleId,
    required this.description,
    required this.status,
    required this.urgency,
    required this.currentOdometer,
    required this.createdAt,
    required this.updatedAt,
    this.targetOdometer,
    this.targetDate,
    this.originMaintenanceId,
    this.remainingKm,
    this.remainingDays,
  });

  final String id;
  final String vehicleId;
  final String description;
  final int? targetOdometer;
  final DateTime? targetDate;
  final ReminderStatus status;
  final ReminderUrgency urgency;
  final String? originMaintenanceId;
  final int currentOdometer;
  final int? remainingKm;
  final int? remainingDays;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class ReminderDraft {
  const ReminderDraft({
    required this.vehicleId,
    required this.description,
    this.status = ReminderStatus.active,
    this.targetOdometer,
    this.targetDate,
    this.originMaintenanceId,
  });

  final String vehicleId;
  final String description;
  final ReminderStatus status;
  final int? targetOdometer;
  final DateTime? targetDate;
  final String? originMaintenanceId;
}
