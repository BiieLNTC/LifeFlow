import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeflow_app/core/supabase/supabase_provider.dart';
import 'package:lifeflow_app/core/sync/offline_repository_support.dart';
import 'package:lifeflow_app/core/sync/offline_store.dart';
import 'package:lifeflow_app/core/sync/sync_models.dart';
import 'package:lifeflow_app/features/vehicles/domain/vehicle.dart';
import 'package:lifeflow_app/features/vehicles/domain/vehicle_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseVehicleRepository(
    client,
    OfflineRepositorySupport(client, ref.watch(offlineStoreProvider)),
  );
});

class SupabaseVehicleRepository implements VehicleRepository {
  SupabaseVehicleRepository(this._client, this._offline);

  final SupabaseClient _client;
  final OfflineRepositorySupport _offline;
  final Uuid _uuid = const Uuid();

  @override
  Future<List<Vehicle>> getVehicles() {
    return _guard(() async {
      final rows = await _offline.readList(
        entityType: 'vehicle',
        parentId: null,
        remote: () async =>
            (await _client
                    .from('vehicles')
                    .select()
                    .isFilter('deleted_at', null)
                    .order('updated_at', ascending: false))
                .cast<Map<String, dynamic>>(),
      );
      final vehicles = rows.map(_vehicleFromJson).toList();
      vehicles.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return vehicles;
    });
  }

  @override
  Future<Vehicle> getVehicle(String id) {
    return _guard(() async {
      final row = await _offline.readOne(
        entityType: 'vehicle',
        recordId: id,
        remote: () => _client
            .from('vehicles')
            .select()
            .eq('id', id)
            .isFilter('deleted_at', null)
            .single(),
      );
      return _vehicleFromJson(row);
    });
  }

  @override
  Future<Vehicle> createVehicle(VehicleDraft draft) {
    return _guard(() async {
      final id = _uuid.v7();
      final payload = {'id': id, ..._draftToJson(draft)};
      final row = await _offline.save(
        entityType: 'vehicle',
        recordId: id,
        parentId: null,
        localRecord: _localJson(id, draft),
        remotePayload: payload,
        operation: SyncOperation.create,
        remote: () =>
            _client.from('vehicles').insert(payload).select().single(),
      );
      return _vehicleFromJson(row);
    });
  }

  @override
  Future<Vehicle> updateVehicle(String id, VehicleDraft draft) {
    return _guard(() async {
      final previous = await _offline.store.readRecord(
        userId: _offline.userId,
        entityType: 'vehicle',
        recordId: id,
      );
      final payload = {'id': id, ..._draftToJson(draft)};
      final row = await _offline.save(
        entityType: 'vehicle',
        recordId: id,
        parentId: null,
        localRecord: _localJson(id, draft, previous: previous),
        remotePayload: payload,
        operation: SyncOperation.update,
        remote: () => _client
            .from('vehicles')
            .update(_draftToJson(draft))
            .eq('id', id)
            .select()
            .single(),
      );
      return _vehicleFromJson(row);
    });
  }

  @override
  Future<void> deleteVehicle(String id) {
    return _guard(() async {
      await _offline.delete(
        entityType: 'vehicle',
        recordId: id,
        parentId: null,
        remote: () async {
          await _client
              .from('vehicles')
              .update({
                'active': false,
                'deleted_at': DateTime.now().toUtc().toIso8601String(),
              })
              .eq('id', id)
              .select('id')
              .single();
        },
      );
    });
  }

  Map<String, Object?> _draftToJson(VehicleDraft draft) {
    return {
      'vehicle_type': draft.type.databaseValue,
      'nickname': draft.nickname.trim(),
      'brand': draft.brand.trim(),
      'model': draft.model.trim(),
      'version': _optionalText(draft.version),
      'manufacture_year': draft.manufactureYear,
      'model_year': draft.modelYear,
      'license_plate': _normalizePlate(draft.licensePlate),
      'fuel_type': draft.fuelType?.databaseValue,
      'current_odometer': draft.currentOdometer,
      'purchase_date': draft.purchaseDate?.toIso8601String().split('T').first,
      'purchase_price': draft.purchasePrice,
      'notes': _optionalText(draft.notes),
      'active': true,
    };
  }

  Map<String, dynamic> _localJson(
    String id,
    VehicleDraft draft, {
    Map<String, dynamic>? previous,
  }) {
    final now = DateTime.now().toUtc().toIso8601String();
    return {
      'id': id,
      'user_id': _offline.userId,
      ..._draftToJson(draft),
      'photo_path': previous?['photo_path'],
      'created_at': previous?['created_at'] ?? now,
      'updated_at': now,
      'deleted_at': null,
      'last_synced_at': previous?['last_synced_at'],
    };
  }

  Vehicle _vehicleFromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as String,
      type: VehicleType.fromDatabase(json['vehicle_type'] as String),
      nickname: json['nickname'] as String,
      brand: json['brand'] as String,
      model: json['model'] as String,
      version: json['version'] as String?,
      manufactureYear: json['manufacture_year'] as int?,
      modelYear: json['model_year'] as int?,
      licensePlate: json['license_plate'] as String?,
      fuelType: json['fuel_type'] == null
          ? null
          : FuelType.fromDatabase(json['fuel_type'] as String),
      currentOdometer: json['current_odometer'] as int,
      purchaseDate: json['purchase_date'] == null
          ? null
          : DateTime.parse(json['purchase_date'] as String),
      purchasePrice: _decimalFromJson(json['purchase_price']),
      notes: json['notes'] as String?,
      photoPath: json['photo_path'] as String?,
      active: json['active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toUtc(),
    );
  }

  String? _optionalText(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  String? _normalizePlate(String? value) {
    return _optionalText(value)
        ?.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
        .toUpperCase();
  }

  double? _decimalFromJson(Object? value) {
    return switch (value) {
      null => null,
      num number => number.toDouble(),
      String text => double.parse(text),
      _ => throw const FormatException('Valor monetário inválido.'),
    };
  }

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on PostgrestException catch (error) {
      throw VehicleFailure(_messageFor(error));
    } catch (error) {
      if (error is VehicleFailure) rethrow;
      throw const VehicleFailure(
        'Não foi possível conectar ao serviço. Verifique sua internet e tente novamente.',
      );
    }
  }

  String _messageFor(PostgrestException error) {
    if (error.message.contains('future')) {
      return 'A data da compra não pode estar no futuro.';
    }
    return switch (error.code) {
      '23505' => 'Já existe um veículo ativo com esta placa.',
      '23514' || '22001' => 'Revise os dados informados e tente novamente.',
      '42501' => 'Você não tem permissão para acessar este veículo.',
      'PGRST116' => 'Veículo não encontrado ou sem permissão de acesso.',
      _ => 'Não foi possível salvar o veículo. Tente novamente.',
    };
  }
}
