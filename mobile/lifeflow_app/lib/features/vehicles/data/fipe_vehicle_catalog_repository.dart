import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:lifeflow_app/features/vehicles/domain/vehicle.dart';
import 'package:lifeflow_app/features/vehicles/domain/vehicle_catalog.dart';

final vehicleCatalogRepositoryProvider = Provider<VehicleCatalogRepository>((
  ref,
) {
  final client = http.Client();
  ref.onDispose(client.close);
  return FipeVehicleCatalogRepository(client);
});

class FipeVehicleCatalogRepository implements VehicleCatalogRepository {
  FipeVehicleCatalogRepository(this._client);

  static const _baseUrl = 'https://fipe.parallelum.com.br/api/v2';

  final http.Client _client;
  final Map<VehicleType, List<VehicleCatalogOption>> _brandsCache = {};
  final Map<String, List<VehicleCatalogOption>> _modelsCache = {};

  @override
  Future<List<VehicleCatalogOption>> getBrands(VehicleType type) async {
    final cached = _brandsCache[type];
    if (cached != null) return cached;

    final options = await _getOptions('/${_typePath(type)}/brands');
    _brandsCache[type] = options;
    return options;
  }

  @override
  Future<List<VehicleCatalogOption>> getModels(
    VehicleType type,
    String brandCode,
  ) async {
    final cacheKey = '${type.databaseValue}:$brandCode';
    final cached = _modelsCache[cacheKey];
    if (cached != null) return cached;

    final options = await _getOptions(
      '/${_typePath(type)}/brands/$brandCode/models',
    );
    _modelsCache[cacheKey] = options;
    return options;
  }

  Future<List<VehicleCatalogOption>> _getOptions(String path) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$_baseUrl$path'),
            headers: const {'accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 429) {
        throw const VehicleCatalogFailure(
          'O catálogo atingiu o limite de consultas. Preencha manualmente.',
        );
      }
      if (response.statusCode != 200) {
        throw const VehicleCatalogFailure(
          'O catálogo de veículos está indisponível no momento.',
        );
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! List) {
        throw const FormatException('Resposta inesperada do catálogo.');
      }

      final options =
          decoded
              .whereType<Map<String, dynamic>>()
              .map(
                (item) => VehicleCatalogOption(
                  code: item['code'].toString(),
                  name: item['name'] as String,
                ),
              )
              .toList(growable: false)
            ..sort((first, second) => first.name.compareTo(second.name));
      return options;
    } on VehicleCatalogFailure {
      rethrow;
    } catch (_) {
      throw const VehicleCatalogFailure(
        'Não foi possível consultar o catálogo. Confira sua internet.',
      );
    }
  }

  String _typePath(VehicleType type) {
    return switch (type) {
      VehicleType.car => 'cars',
      VehicleType.motorcycle => 'motorcycles',
    };
  }
}
