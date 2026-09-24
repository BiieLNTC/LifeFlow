import 'package:lifeflow_app/features/vehicles/domain/vehicle.dart';

class Refueling {
  const Refueling({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.odometer,
    required this.liters,
    required this.unitPrice,
    required this.totalAmount,
    required this.fuelType,
    required this.fullTank,
    required this.createdAt,
    required this.updatedAt,
    this.gasStation,
    this.notes,
    this.consumptionKmL,
  });
  final String id, vehicleId;
  final DateTime date, createdAt, updatedAt;
  final int odometer;
  final double liters, unitPrice, totalAmount;
  final FuelType fuelType;
  final bool fullTank;
  final String? gasStation, notes;
  final double? consumptionKmL;
}

class RefuelingDraft {
  const RefuelingDraft({
    required this.vehicleId,
    required this.date,
    required this.odometer,
    required this.liters,
    required this.unitPrice,
    required this.totalAmount,
    required this.fuelType,
    required this.fullTank,
    this.gasStation,
    this.notes,
  });
  final String vehicleId;
  final DateTime date;
  final int odometer;
  final double liters, unitPrice, totalAmount;
  final FuelType fuelType;
  final bool fullTank;
  final String? gasStation, notes;
}
