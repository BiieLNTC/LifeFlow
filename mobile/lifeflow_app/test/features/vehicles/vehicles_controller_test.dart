import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeflow_app/features/vehicles/data/supabase_vehicle_repository.dart';
import 'package:lifeflow_app/features/vehicles/domain/vehicle.dart';
import 'package:lifeflow_app/features/vehicles/presentation/vehicles_controller.dart';

import '../../support/fake_vehicle_repository.dart';

void main() {
  late FakeVehicleRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeVehicleRepository(vehicles: [fakeVehicle()]);
    container = ProviderContainer(
      overrides: [vehicleRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(() => container.dispose());

  test('carrega os veículos existentes', () async {
    final vehicles = await container.read(vehiclesControllerProvider.future);

    expect(vehicles, hasLength(1));
    expect(vehicles.single.nickname, 'Meu carro');
  });

  test('cria veículo e atualiza a lista', () async {
    await container.read(vehiclesControllerProvider.future);

    await container.read(vehiclesControllerProvider.notifier).create(_draft());

    final vehicles = container.read(vehiclesControllerProvider).value!;
    expect(vehicles, hasLength(2));
    expect(vehicles.first.id, 'created-id');
  });

  test('edita e remove veículo da lista', () async {
    await container.read(vehiclesControllerProvider.future);
    final controller = container.read(vehiclesControllerProvider.notifier);

    await controller.updateVehicle(
      'vehicle-id',
      _draft(nickname: 'Carro atualizado'),
    );
    expect(
      container.read(vehiclesControllerProvider).value!.single.nickname,
      'Carro atualizado',
    );

    await controller.delete('vehicle-id');
    expect(container.read(vehiclesControllerProvider).value, isEmpty);
  });
}

VehicleDraft _draft({String nickname = 'Moto da cidade'}) {
  return VehicleDraft(
    type: VehicleType.motorcycle,
    nickname: nickname,
    brand: 'Honda',
    model: 'CB 500',
    currentOdometer: 25000,
  );
}
