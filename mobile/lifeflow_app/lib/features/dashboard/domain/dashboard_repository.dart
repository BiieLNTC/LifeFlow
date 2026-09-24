import 'package:lifeflow_app/features/dashboard/domain/vehicle_dashboard.dart';

abstract interface class DashboardRepository {
  Future<List<VehicleDashboard>> getDashboard();
}

class DashboardFailure implements Exception {
  const DashboardFailure(this.message);
  final String message;
}
