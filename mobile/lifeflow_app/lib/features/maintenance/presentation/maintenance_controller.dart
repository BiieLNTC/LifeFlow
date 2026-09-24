import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeflow_app/features/maintenance/data/supabase_maintenance_repository.dart';
import 'package:lifeflow_app/features/maintenance/domain/maintenance.dart';
import 'package:lifeflow_app/features/vehicles/presentation/vehicles_controller.dart';
import 'package:uuid/uuid.dart';

final maintenancesProvider =
    AsyncNotifierProvider.family<
      MaintenancesController,
      List<Maintenance>,
      String
    >(MaintenancesController.new);

final maintenanceDetailsProvider = FutureProvider.family<Maintenance, String>((
  ref,
  id,
) {
  return ref.watch(maintenanceRepositoryProvider).getMaintenance(id);
});

class MaintenancesController extends AsyncNotifier<List<Maintenance>> {
  MaintenancesController(this.vehicleId);

  final String vehicleId;
  final _uuid = const Uuid();

  @override
  Future<List<Maintenance>> build() {
    return ref.watch(maintenanceRepositoryProvider).getMaintenances(vehicleId);
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(maintenanceRepositoryProvider).getMaintenances(vehicleId),
    );
  }

  Future<Maintenance> create(MaintenanceDraft draft) async {
    final result = await ref
        .read(maintenanceRepositoryProvider)
        .saveMaintenance(_uuid.v7(), draft);
    state = AsyncData([result, ...?state.value]);
    _refreshVehicleOdometer();
    return result;
  }

  Future<Maintenance> updateMaintenance(
    String id,
    MaintenanceDraft draft,
  ) async {
    final result = await ref
        .read(maintenanceRepositoryProvider)
        .saveMaintenance(id, draft);
    state = AsyncData([
      for (final item in state.value ?? const <Maintenance>[])
        if (item.id == id) result else item,
    ]);
    ref.invalidate(maintenanceDetailsProvider(id));
    _refreshVehicleOdometer();
    return result;
  }

  Future<void> delete(String id) async {
    await ref.read(maintenanceRepositoryProvider).deleteMaintenance(id);
    state = AsyncData(
      (state.value ?? const <Maintenance>[])
          .where((item) => item.id != id)
          .toList(growable: false),
    );
    ref.invalidate(maintenanceDetailsProvider(id));
  }

  void _refreshVehicleOdometer() {
    ref
      ..invalidate(vehicleDetailsProvider(vehicleId))
      ..invalidate(vehiclesControllerProvider);
  }
}
