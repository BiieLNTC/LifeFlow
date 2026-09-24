import 'package:lifeflow_app/features/reminders/domain/reminder.dart';
import 'package:lifeflow_app/features/vehicles/domain/vehicle.dart';

class DashboardReminder {
  const DashboardReminder({
    required this.id,
    required this.description,
    required this.urgency,
    this.targetOdometer,
    this.targetDate,
    this.remainingKm,
    this.remainingDays,
  });

  final String id;
  final String description;
  final ReminderUrgency urgency;
  final int? targetOdometer;
  final DateTime? targetDate;
  final int? remainingKm;
  final int? remainingDays;
}

class VehicleDashboard {
  const VehicleDashboard({
    required this.vehicleId,
    required this.vehicleType,
    required this.nickname,
    required this.brand,
    required this.model,
    required this.currentOdometer,
    required this.monthlySpending,
    required this.attentionCount,
    this.version,
    this.manufactureYear,
    this.modelYear,
    this.photoPath,
    this.monthlyConsumptionKmL,
    this.costPerKm,
    this.monthlyDistanceKm,
    this.nextReminder,
  });

  final String vehicleId;
  final VehicleType vehicleType;
  final String nickname;
  final String brand;
  final String model;
  final String? version;
  final int? manufactureYear;
  final int? modelYear;
  final int currentOdometer;
  final String? photoPath;
  final double monthlySpending;
  final double? monthlyConsumptionKmL;
  final double? costPerKm;
  final int? monthlyDistanceKm;
  final int attentionCount;
  final DashboardReminder? nextReminder;

  String get description => '$brand $model';
}
