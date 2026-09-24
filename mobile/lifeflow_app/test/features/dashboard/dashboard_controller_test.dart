import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeflow_app/features/dashboard/data/supabase_dashboard_repository.dart';
import 'package:lifeflow_app/features/dashboard/domain/vehicle_dashboard.dart';
import 'package:lifeflow_app/features/dashboard/presentation/dashboard_controller.dart';
import 'package:lifeflow_app/features/vehicles/domain/vehicle.dart';

import '../../support/fake_dashboard_repository.dart';

void main() {
  test('carrega e atualiza o resumo dos veículos', () async {
    final repository = FakeDashboardRepository(vehicles: [_dashboard(100)]);
    final container = ProviderContainer(
      overrides: [dashboardRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      dashboardProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    expect((await container.read(dashboardProvider.future)).single.monthlySpending, 100);

    repository.vehicles = [_dashboard(250)];
    await container.read(dashboardProvider.notifier).reload();
    expect(container.read(dashboardProvider).value?.single.monthlySpending, 250);
  });
}

VehicleDashboard _dashboard(double spending) => VehicleDashboard(
  vehicleId: 'vehicle-id',
  vehicleType: VehicleType.car,
  nickname: 'i30',
  brand: 'Hyundai',
  model: 'i30',
  currentOdometer: 127340,
  monthlySpending: spending,
  attentionCount: 0,
);
