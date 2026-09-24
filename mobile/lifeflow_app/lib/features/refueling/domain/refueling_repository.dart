import 'package:lifeflow_app/features/refueling/domain/refueling.dart';

class RefuelingFailure implements Exception {
  const RefuelingFailure(this.message);
  final String message;
}

abstract interface class RefuelingRepository {
  Future<List<Refueling>> getRefuelings(String vehicleId);
  Future<Refueling> getRefueling(String id);
  Future<Refueling> saveRefueling(String id, RefuelingDraft draft);
  Future<void> deleteRefueling(String id);
}
