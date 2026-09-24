import 'package:lifeflow_app/features/vehicles/domain/vehicle.dart';

class VehicleFailure implements Exception {
  const VehicleFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class VehicleRepository {
  Future<List<Vehicle>> getVehicles();

  Future<Vehicle> getVehicle(String id);

  Future<Vehicle> createVehicle(VehicleDraft draft);

  Future<Vehicle> updateVehicle(String id, VehicleDraft draft);

  Future<void> deleteVehicle(String id);
}
