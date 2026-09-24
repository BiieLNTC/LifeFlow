import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeflow_app/features/vehicles/data/fipe_vehicle_catalog_repository.dart';
import 'package:lifeflow_app/features/vehicles/domain/vehicle.dart';
import 'package:lifeflow_app/features/vehicles/domain/vehicle_catalog.dart';
import 'package:lifeflow_app/features/vehicles/presentation/vehicle_form_page.dart';

void main() {
  testWidgets('seleciona marca e modelo e sugere o apelido', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vehicleCatalogRepositoryProvider.overrideWithValue(
            const _FakeVehicleCatalogRepository(),
          ),
        ],
        child: const MaterialApp(home: VehicleFormPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Toque para escolher').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hyundai'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Toque para escolher').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('i30 2.0 16V'));
    await tester.pumpAndSettle();

    final nicknameField = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Apelido'),
    );
    expect(nicknameField.controller?.text, 'i30');
    expect(find.text('Hyundai'), findsOneWidget);
    expect(find.text('i30 2.0 16V'), findsOneWidget);
  });
}

class _FakeVehicleCatalogRepository implements VehicleCatalogRepository {
  const _FakeVehicleCatalogRepository();

  @override
  Future<List<VehicleCatalogOption>> getBrands(VehicleType type) async {
    return const [VehicleCatalogOption(code: '26', name: 'Hyundai')];
  }

  @override
  Future<List<VehicleCatalogOption>> getModels(
    VehicleType type,
    String brandCode,
  ) async {
    return const [VehicleCatalogOption(code: '1234', name: 'i30 2.0 16V')];
  }
}
