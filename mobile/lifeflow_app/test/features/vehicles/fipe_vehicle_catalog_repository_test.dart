import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lifeflow_app/features/vehicles/data/fipe_vehicle_catalog_repository.dart';
import 'package:lifeflow_app/features/vehicles/domain/vehicle.dart';
import 'package:lifeflow_app/features/vehicles/domain/vehicle_catalog.dart';

void main() {
  test('carrega e ordena as marcas de carros', () async {
    var requests = 0;
    final repository = FipeVehicleCatalogRepository(
      MockClient((request) async {
        requests++;
        expect(request.url.path, '/api/v2/cars/brands');
        return http.Response(
          '[{"code":"59","name":"VW"},{"code":"26","name":"Hyundai"}]',
          200,
        );
      }),
    );

    final firstResult = await repository.getBrands(VehicleType.car);
    final cachedResult = await repository.getBrands(VehicleType.car);

    expect(firstResult.map((item) => item.name), ['Hyundai', 'VW']);
    expect(cachedResult, same(firstResult));
    expect(requests, 1);
  });

  test('carrega os modelos da marca escolhida', () async {
    final repository = FipeVehicleCatalogRepository(
      MockClient((request) async {
        expect(request.url.path, '/api/v2/cars/brands/26/models');
        return http.Response(
          '[{"code":"1234","name":"i30 2.0 16V"}]',
          200,
        );
      }),
    );

    final result = await repository.getModels(VehicleType.car, '26');

    expect(result.single.code, '1234');
    expect(result.single.name, 'i30 2.0 16V');
  });

  test('informa quando o limite do catálogo é atingido', () async {
    final repository = FipeVehicleCatalogRepository(
      MockClient((_) async => http.Response('', 429)),
    );

    expect(
      () => repository.getBrands(VehicleType.motorcycle),
      throwsA(
        isA<VehicleCatalogFailure>().having(
          (error) => error.message,
          'mensagem',
          contains('limite'),
        ),
      ),
    );
  });
}
