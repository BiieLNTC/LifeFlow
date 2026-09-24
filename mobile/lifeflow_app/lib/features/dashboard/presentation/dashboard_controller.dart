import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeflow_app/features/dashboard/data/supabase_dashboard_repository.dart';
import 'package:lifeflow_app/features/dashboard/domain/vehicle_dashboard.dart';

final dashboardProvider =
    AsyncNotifierProvider<DashboardController, List<VehicleDashboard>>(
      DashboardController.new,
    );

class DashboardController extends AsyncNotifier<List<VehicleDashboard>> {
  @override
  Future<List<VehicleDashboard>> build() =>
      ref.watch(dashboardRepositoryProvider).getDashboard();

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(dashboardRepositoryProvider).getDashboard(),
    );
  }
}
