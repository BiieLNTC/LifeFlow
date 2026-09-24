enum MaintenanceType {
  preventive('preventive', 'Preventiva'),
  corrective('corrective', 'Corretiva');

  const MaintenanceType(this.databaseValue, this.label);
  final String databaseValue;
  final String label;

  static MaintenanceType fromDatabase(String value) =>
      values.firstWhere((item) => item.databaseValue == value);
}

enum MaintenanceCategory {
  oil('oil', 'Óleo'),
  oilFilter('oil_filter', 'Filtro de óleo'),
  airFilter('air_filter', 'Filtro de ar'),
  fuelFilter('fuel_filter', 'Filtro de combustível'),
  brakes('brakes', 'Freios'),
  tires('tires', 'Pneus'),
  suspension('suspension', 'Suspensão'),
  belts('belts', 'Correias'),
  battery('battery', 'Bateria'),
  airConditioning('air_conditioning', 'Ar-condicionado'),
  alignment('alignment', 'Alinhamento'),
  balancing('balancing', 'Balanceamento'),
  other('other', 'Outros');

  const MaintenanceCategory(this.databaseValue, this.label);
  final String databaseValue;
  final String label;

  static MaintenanceCategory fromDatabase(String value) =>
      values.firstWhere((item) => item.databaseValue == value);
}

class MaintenanceItem {
  const MaintenanceItem({
    required this.id,
    required this.category,
    required this.description,
    required this.partAmount,
    required this.laborAmount,
    this.nextReplacementOdometer,
    this.nextReplacementDate,
  });

  final String id;
  final MaintenanceCategory category;
  final String description;
  final double partAmount;
  final double laborAmount;
  final int? nextReplacementOdometer;
  final DateTime? nextReplacementDate;

  double get total => partAmount + laborAmount;
  bool get hasNextReplacement =>
      nextReplacementOdometer != null || nextReplacementDate != null;
}

class Maintenance {
  const Maintenance({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.odometer,
    required this.type,
    required this.totalAmount,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
    this.workshop,
    this.notes,
  });

  final String id;
  final String vehicleId;
  final DateTime date;
  final int odometer;
  final MaintenanceType type;
  final String? workshop;
  final String? notes;
  final double totalAmount;
  final List<MaintenanceItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class MaintenanceItemDraft {
  const MaintenanceItemDraft({
    required this.id,
    required this.category,
    required this.description,
    required this.partAmount,
    required this.laborAmount,
    this.nextReplacementOdometer,
    this.nextReplacementDate,
  });

  final String id;
  final MaintenanceCategory category;
  final String description;
  final double partAmount;
  final double laborAmount;
  final int? nextReplacementOdometer;
  final DateTime? nextReplacementDate;
}

class MaintenanceDraft {
  const MaintenanceDraft({
    required this.vehicleId,
    required this.date,
    required this.odometer,
    required this.type,
    required this.items,
    this.workshop,
    this.notes,
  });

  final String vehicleId;
  final DateTime date;
  final int odometer;
  final MaintenanceType type;
  final String? workshop;
  final String? notes;
  final List<MaintenanceItemDraft> items;
}
