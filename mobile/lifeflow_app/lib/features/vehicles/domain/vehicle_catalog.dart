import 'package:lifeflow_app/features/vehicles/domain/vehicle.dart';

class VehicleCatalogOption {
  const VehicleCatalogOption({required this.code, required this.name});

  final String code;
  final String name;
}

class VehicleCatalogFailure implements Exception {
  const VehicleCatalogFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class VehicleCatalogRepository {
  Future<List<VehicleCatalogOption>> getBrands(VehicleType type);

  Future<List<VehicleCatalogOption>> getModels(
    VehicleType type,
    String brandCode,
  );
}
