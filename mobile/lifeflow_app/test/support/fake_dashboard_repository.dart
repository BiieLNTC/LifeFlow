import 'package:lifeflow_app/features/dashboard/domain/dashboard_repository.dart';
import 'package:lifeflow_app/features/dashboard/domain/vehicle_dashboard.dart';

class FakeDashboardRepository implements DashboardRepository {
  FakeDashboardRepository({this.vehicles = const []});

  List<VehicleDashboard> vehicles;
  Object? nextError;

  @override
  Future<List<VehicleDashboard>> getDashboard() async {
    final error = nextError;
    nextError = null;
    if (error != null) throw error;
    return [...vehicles];
  }
}
