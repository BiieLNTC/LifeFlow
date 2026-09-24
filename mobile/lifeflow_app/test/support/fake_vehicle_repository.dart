import 'package:lifeflow_app/features/vehicles/domain/vehicle.dart';
import 'package:lifeflow_app/features/vehicles/domain/vehicle_repository.dart';

class FakeVehicleRepository implements VehicleRepository {
  FakeVehicleRepository({List<Vehicle> vehicles = const []})
    : _vehicles = [...vehicles];

  List<Vehicle> _vehicles;
  Object? nextError;

  @override
  Future<List<Vehicle>> getVehicles() async {
    _throwNextErrorIfNeeded();
    return [..._vehicles];
  }

  @override
  Future<Vehicle> getVehicle(String id) async {
    _throwNextErrorIfNeeded();
    return _vehicles.firstWhere((vehicle) => vehicle.id == id);
  }

  @override
  Future<Vehicle> createVehicle(VehicleDraft draft) async {
    _throwNextErrorIfNeeded();
    final now = DateTime.utc(2026, 9, 20);
    final vehicle = Vehicle(
      id: 'created-id',
      type: draft.type,
      nickname: draft.nickname,
      brand: draft.brand,
      model: draft.model,
      version: draft.version,
      manufactureYear: draft.manufactureYear,
      modelYear: draft.modelYear,
      licensePlate: draft.licensePlate,
      fuelType: draft.fuelType,
      currentOdometer: draft.currentOdometer,
      purchaseDate: draft.purchaseDate,
      purchasePrice: draft.purchasePrice,
      notes: draft.notes,
      active: true,
      createdAt: now,
      updatedAt: now,
    );
    _vehicles = [vehicle, ..._vehicles];
    return vehicle;
  }

  @override
  Future<Vehicle> updateVehicle(String id, VehicleDraft draft) async {
    _throwNextErrorIfNeeded();
    final previous = await getVehicle(id);
    final updated = Vehicle(
      id: previous.id,
      type: draft.type,
      nickname: draft.nickname,
      brand: draft.brand,
      model: draft.model,
      version: draft.version,
      manufactureYear: draft.manufactureYear,
      modelYear: draft.modelYear,
      licensePlate: draft.licensePlate,
      fuelType: draft.fuelType,
      currentOdometer: draft.currentOdometer,
      purchaseDate: draft.purchaseDate,
      purchasePrice: draft.purchasePrice,
      notes: draft.notes,
      photoPath: previous.photoPath,
      active: true,
      createdAt: previous.createdAt,
      updatedAt: DateTime.utc(2026, 9, 21),
    );
    _vehicles = [
      for (final vehicle in _vehicles)
        if (vehicle.id == id) updated else vehicle,
    ];
    return updated;
  }

  @override
  Future<void> deleteVehicle(String id) async {
    _throwNextErrorIfNeeded();
    _vehicles = _vehicles.where((vehicle) => vehicle.id != id).toList();
  }

  void _throwNextErrorIfNeeded() {
    final error = nextError;
    nextError = null;
    if (error != null) throw error;
  }
}

Vehicle fakeVehicle({String id = 'vehicle-id', String nickname = 'Meu carro'}) {
  final now = DateTime.utc(2026, 9, 20);
  return Vehicle(
    id: id,
    type: VehicleType.car,
    nickname: nickname,
    brand: 'Hyundai',
    model: 'i30',
    manufactureYear: 2010,
    modelYear: 2011,
    fuelType: FuelType.gasoline,
    currentOdometer: 127340,
    active: true,
    createdAt: now,
    updatedAt: now,
  );
}
