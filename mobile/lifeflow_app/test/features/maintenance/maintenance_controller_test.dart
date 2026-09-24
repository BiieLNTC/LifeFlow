import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeflow_app/features/maintenance/data/supabase_maintenance_repository.dart';
import 'package:lifeflow_app/features/maintenance/domain/maintenance.dart';
import 'package:lifeflow_app/features/maintenance/presentation/maintenance_controller.dart';

import '../../support/fake_maintenance_repository.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        maintenanceRepositoryProvider.overrideWithValue(
          FakeMaintenanceRepository(maintenances: [fakeMaintenance()]),
        ),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('carrega, cria, edita e remove manutenções do veículo', () async {
    final subscription = container.listen(
      maintenancesProvider('vehicle-id'),
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    expect(
      (await container.read(maintenancesProvider('vehicle-id').future)).length,
      1,
    );

    final controller = container.read(
      maintenancesProvider('vehicle-id').notifier,
    );
    final created = await controller.create(_draft(description: 'Freios'));
    expect(container.read(maintenancesProvider('vehicle-id')).value?.length, 2);
    expect(created.totalAmount, 150);

    await controller.updateMaintenance(
      created.id,
      _draft(description: 'Pastilhas'),
    );
    expect(
      container
          .read(maintenancesProvider('vehicle-id'))
          .value
          ?.first
          .items
          .single
          .description,
      'Pastilhas',
    );

    await controller.delete(created.id);
    expect(container.read(maintenancesProvider('vehicle-id')).value?.length, 1);
  });
}

MaintenanceDraft _draft({required String description}) => MaintenanceDraft(
  vehicleId: 'vehicle-id',
  date: DateTime.utc(2026, 9, 20),
  odometer: 127340,
  type: MaintenanceType.corrective,
  items: [
    MaintenanceItemDraft(
      id: 'draft-item-id',
      category: MaintenanceCategory.brakes,
      description: description,
      partAmount: 100,
      laborAmount: 50,
    ),
  ],
);
