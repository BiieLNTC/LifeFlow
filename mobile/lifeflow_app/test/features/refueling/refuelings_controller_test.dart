import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeflow_app/features/refueling/data/supabase_refueling_repository.dart';
import 'package:lifeflow_app/features/refueling/domain/refueling.dart';
import 'package:lifeflow_app/features/refueling/domain/refueling_repository.dart';
import 'package:lifeflow_app/features/refueling/presentation/refuelings_controller.dart';
import 'package:lifeflow_app/features/vehicles/domain/vehicle.dart';

void main() {
  test('cria, edita e remove abastecimento', () async {
    final container = ProviderContainer(
      overrides: [refuelingRepositoryProvider.overrideWithValue(_Fake())],
    );
    addTearDown(container.dispose);
    final sub = container.listen(
      refuelingsProvider('vehicle-id'),
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(sub.close);
    await container.read(refuelingsProvider('vehicle-id').future);
    final controller = container.read(
      refuelingsProvider('vehicle-id').notifier,
    );
    final created = await controller.create(_draft(50));
    expect(created.totalAmount, 50);
    await controller.updateRefueling(created.id, _draft(60));
    expect(
      container
          .read(refuelingsProvider('vehicle-id'))
          .value
          ?.single
          .totalAmount,
      60,
    );
    await controller.delete(created.id);
    expect(container.read(refuelingsProvider('vehicle-id')).value, isEmpty);
  });
}

RefuelingDraft _draft(double total) => RefuelingDraft(
  vehicleId: 'vehicle-id',
  date: DateTime.utc(2026, 9, 20),
  odometer: 100,
  liters: 10,
  unitPrice: total / 10,
  totalAmount: total,
  fuelType: FuelType.gasoline,
  fullTank: true,
);

class _Fake implements RefuelingRepository {
  Refueling? value;
  @override
  Future<List<Refueling>> getRefuelings(String vehicleId) async =>
      value == null ? [] : [value!];
  @override
  Future<Refueling> getRefueling(String id) async => value!;
  @override
  Future<Refueling> saveRefueling(String id, RefuelingDraft d) async =>
      value = Refueling(
        id: id,
        vehicleId: d.vehicleId,
        date: d.date,
        odometer: d.odometer,
        liters: d.liters,
        unitPrice: d.unitPrice,
        totalAmount: d.totalAmount,
        fuelType: d.fuelType,
        fullTank: d.fullTank,
        createdAt: d.date,
        updatedAt: d.date,
      );
  @override
  Future<void> deleteRefueling(String id) async => value = null;
}
