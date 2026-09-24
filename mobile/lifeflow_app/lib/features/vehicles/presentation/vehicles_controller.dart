import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeflow_app/features/vehicles/data/supabase_vehicle_repository.dart';
import 'package:lifeflow_app/features/vehicles/domain/vehicle.dart';

final vehiclesControllerProvider =
    AsyncNotifierProvider<VehiclesController, List<Vehicle>>(
      VehiclesController.new,
    );

final vehicleDetailsProvider = FutureProvider.family<Vehicle, String>((
  ref,
  id,
) {
  return ref.watch(vehicleRepositoryProvider).getVehicle(id);
});

class VehiclesController extends AsyncNotifier<List<Vehicle>> {
  @override
  Future<List<Vehicle>> build() {
    return ref.watch(vehicleRepositoryProvider).getVehicles();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(vehicleRepositoryProvider).getVehicles(),
    );
  }

  Future<Vehicle> create(VehicleDraft draft) async {
    final vehicle = await ref
        .read(vehicleRepositoryProvider)
        .createVehicle(draft);
    final current = state.value ?? const <Vehicle>[];
    state = AsyncData([vehicle, ...current]);
    return vehicle;
  }

  Future<Vehicle> updateVehicle(String id, VehicleDraft draft) async {
    final vehicle = await ref
        .read(vehicleRepositoryProvider)
        .updateVehicle(id, draft);
    final current = state.value ?? const <Vehicle>[];
    state = AsyncData([
      for (final item in current)
        if (item.id == id) vehicle else item,
    ]);
    ref.invalidate(vehicleDetailsProvider(id));
    return vehicle;
  }

  Future<void> delete(String id) async {
    await ref.read(vehicleRepositoryProvider).deleteVehicle(id);
    final current = state.value ?? const <Vehicle>[];
    state = AsyncData(current.where((vehicle) => vehicle.id != id).toList());
    ref.invalidate(vehicleDetailsProvider(id));
  }
}
