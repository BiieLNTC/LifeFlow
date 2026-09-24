import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeflow_app/features/refueling/data/supabase_refueling_repository.dart';
import 'package:lifeflow_app/features/refueling/domain/refueling.dart';
import 'package:lifeflow_app/features/vehicles/presentation/vehicles_controller.dart';
import 'package:uuid/uuid.dart';

final refuelingsProvider =
    AsyncNotifierProvider.family<RefuelingsController, List<Refueling>, String>(
      RefuelingsController.new,
    );

class RefuelingsController extends AsyncNotifier<List<Refueling>> {
  RefuelingsController(this.vehicleId);
  final String vehicleId;
  final _uuid = const Uuid();
  @override
  Future<List<Refueling>> build() =>
      ref.watch(refuelingRepositoryProvider).getRefuelings(vehicleId);
  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(refuelingRepositoryProvider).getRefuelings(vehicleId),
    );
  }

  Future<Refueling> create(RefuelingDraft d) async {
    final r = await ref
        .read(refuelingRepositoryProvider)
        .saveRefueling(_uuid.v7(), d);
    state = AsyncData([r, ...?state.value]);
    _refreshVehicleOdometer();
    return r;
  }

  Future<Refueling> updateRefueling(String id, RefuelingDraft d) async {
    final r = await ref.read(refuelingRepositoryProvider).saveRefueling(id, d);
    state = AsyncData([
      for (final x in state.value ?? const <Refueling>[])
        if (x.id == id) r else x,
    ]);
    _refreshVehicleOdometer();
    return r;
  }

  Future<void> delete(String id) async {
    await ref.read(refuelingRepositoryProvider).deleteRefueling(id);
    state = AsyncData(
      (state.value ?? const <Refueling>[]).where((x) => x.id != id).toList(),
    );
  }

  void _refreshVehicleOdometer() {
    ref
      ..invalidate(vehicleDetailsProvider(vehicleId))
      ..invalidate(vehiclesControllerProvider);
  }
}
