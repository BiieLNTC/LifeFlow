import 'package:lifeflow_app/features/maintenance/domain/maintenance.dart';

class MaintenanceFailure implements Exception {
  const MaintenanceFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract interface class MaintenanceRepository {
  Future<List<Maintenance>> getMaintenances(String vehicleId);
  Future<Maintenance> getMaintenance(String id);
  Future<Maintenance> saveMaintenance(String id, MaintenanceDraft draft);
  Future<void> deleteMaintenance(String id);
}
