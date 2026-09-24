enum VehicleType {
  car('car', 'Carro'),
  motorcycle('motorcycle', 'Moto');

  const VehicleType(this.databaseValue, this.label);

  final String databaseValue;
  final String label;

  static VehicleType fromDatabase(String value) {
    return values.firstWhere((type) => type.databaseValue == value);
  }
}

enum FuelType {
  gasoline('gasoline', 'Gasolina'),
  ethanol('ethanol', 'Etanol'),
  flex('flex', 'Flex'),
  diesel('diesel', 'Diesel'),
  electric('electric', 'Elétrico'),
  hybrid('hybrid', 'Híbrido'),
  other('other', 'Outro');

  const FuelType(this.databaseValue, this.label);

  final String databaseValue;
  final String label;

  static FuelType fromDatabase(String value) {
    return values.firstWhere((type) => type.databaseValue == value);
  }
}

class Vehicle {
  const Vehicle({
    required this.id,
    required this.type,
    required this.nickname,
    required this.brand,
    required this.model,
    required this.currentOdometer,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
    this.version,
    this.manufactureYear,
    this.modelYear,
    this.licensePlate,
    this.fuelType,
    this.purchaseDate,
    this.purchasePrice,
    this.notes,
    this.photoPath,
  });

  final String id;
  final VehicleType type;
  final String nickname;
  final String brand;
  final String model;
  final String? version;
  final int? manufactureYear;
  final int? modelYear;
  final String? licensePlate;
  final FuelType? fuelType;
  final int currentOdometer;
  final DateTime? purchaseDate;
  final double? purchasePrice;
  final String? notes;
  final String? photoPath;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get description => '$brand $model';
}

class VehicleDraft {
  const VehicleDraft({
    required this.type,
    required this.nickname,
    required this.brand,
    required this.model,
    required this.currentOdometer,
    this.version,
    this.manufactureYear,
    this.modelYear,
    this.licensePlate,
    this.fuelType,
    this.purchaseDate,
    this.purchasePrice,
    this.notes,
  });

  final VehicleType type;
  final String nickname;
  final String brand;
  final String model;
  final String? version;
  final int? manufactureYear;
  final int? modelYear;
  final String? licensePlate;
  final FuelType? fuelType;
  final int currentOdometer;
  final DateTime? purchaseDate;
  final double? purchasePrice;
  final String? notes;
}
