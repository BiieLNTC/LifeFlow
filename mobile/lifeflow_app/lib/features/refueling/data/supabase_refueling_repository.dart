import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeflow_app/core/supabase/supabase_provider.dart';
import 'package:lifeflow_app/core/sync/offline_repository_support.dart';
import 'package:lifeflow_app/core/sync/offline_store.dart';
import 'package:lifeflow_app/features/refueling/domain/refueling.dart';
import 'package:lifeflow_app/features/refueling/domain/refueling_repository.dart';
import 'package:lifeflow_app/features/vehicles/domain/vehicle.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final refuelingRepositoryProvider = Provider<RefuelingRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseRefuelingRepository(
    client,
    OfflineRepositorySupport(client, ref.watch(offlineStoreProvider)),
  );
});

class SupabaseRefuelingRepository implements RefuelingRepository {
  SupabaseRefuelingRepository(this._client, this._offline);
  final SupabaseClient _client;
  final OfflineRepositorySupport _offline;
  @override
  Future<List<Refueling>> getRefuelings(String vehicleId) => _guard(() async {
    final rows = await _offline.readList(
      entityType: 'refueling',
      parentId: vehicleId,
      remote: () async =>
          (await _client
                  .from('refueling_details')
                  .select()
                  .eq('vehicle_id', vehicleId)
                  .order('refueling_date', ascending: false)
                  .order('odometer', ascending: false))
              .cast<Map<String, dynamic>>(),
    );
    final result = rows.map(_fromJson).toList();
    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  });
  @override
  Future<Refueling> getRefueling(String id) => _guard(
    () async => _fromJson(
      await _offline.readOne(
        entityType: 'refueling',
        recordId: id,
        remote: () =>
            _client.from('refueling_details').select().eq('id', id).single(),
      ),
    ),
  );
  @override
  Future<Refueling> saveRefueling(String id, RefuelingDraft d) =>
      _guard(() async {
        final payload = {
          'id': id,
          'vehicle_id': d.vehicleId,
          'refueling_date': _date(d.date),
          'odometer': d.odometer,
          'liters': d.liters,
          'unit_price': d.unitPrice,
          'total_amount': d.totalAmount,
          'fuel_type': d.fuelType.databaseValue,
          'full_tank': d.fullTank,
          'gas_station': _text(d.gasStation),
          'notes': _text(d.notes),
          'deleted_at': null,
        };
        final previous = await _offline.store.readRecord(
          userId: _offline.userId,
          entityType: 'refueling',
          recordId: id,
        );
        final row = await _offline.save(
          entityType: 'refueling',
          recordId: id,
          parentId: d.vehicleId,
          localRecord: _localJson(id, d, previous: previous),
          remotePayload: payload,
          remote: () async {
            await _client.from('refuelings').upsert(payload);
            return _client
                .from('refueling_details')
                .select()
                .eq('id', id)
                .single();
          },
        );
        await _offline.store.advanceVehicleOdometer(
          userId: _offline.userId,
          vehicleId: d.vehicleId,
          odometer: d.odometer,
        );
        return _fromJson(row);
      });
  @override
  Future<void> deleteRefueling(String id) => _guard(() async {
    final previous = await _offline.store.readRecord(
      userId: _offline.userId,
      entityType: 'refueling',
      recordId: id,
    );
    await _offline.delete(
      entityType: 'refueling',
      recordId: id,
      parentId: previous?['vehicle_id'] as String?,
      remote: () async {
        await _client
            .from('refuelings')
            .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
            .eq('id', id)
            .select('id')
            .single();
      },
    );
  });
  Refueling _fromJson(Map<String, dynamic> j) => Refueling(
    id: j['id'],
    vehicleId: j['vehicle_id'],
    date: DateTime.parse(j['refueling_date']),
    odometer: j['odometer'],
    liters: _number(j['liters']),
    unitPrice: _number(j['unit_price']),
    totalAmount: _number(j['total_amount']),
    fuelType: FuelType.fromDatabase(j['fuel_type']),
    fullTank: j['full_tank'],
    gasStation: j['gas_station'],
    notes: j['notes'],
    consumptionKmL: j['consumption_km_l'] == null
        ? null
        : _number(j['consumption_km_l']),
    createdAt: DateTime.parse(j['created_at']).toUtc(),
    updatedAt: DateTime.parse(j['updated_at']).toUtc(),
  );
  Map<String, dynamic> _localJson(
    String id,
    RefuelingDraft d, {
    Map<String, dynamic>? previous,
  }) {
    final now = DateTime.now().toUtc().toIso8601String();
    return {
      'id': id,
      'vehicle_id': d.vehicleId,
      'refueling_date': _date(d.date),
      'odometer': d.odometer,
      'liters': d.liters,
      'unit_price': d.unitPrice,
      'total_amount': d.totalAmount,
      'fuel_type': d.fuelType.databaseValue,
      'full_tank': d.fullTank,
      'gas_station': _text(d.gasStation),
      'notes': _text(d.notes),
      'consumption_km_l': previous?['consumption_km_l'],
      'created_at': previous?['created_at'] ?? now,
      'updated_at': now,
      'deleted_at': null,
    };
  }

  double _number(Object? v) =>
      v is num ? v.toDouble() : double.parse(v as String);
  String _date(DateTime d) => d.toIso8601String().split('T').first;
  String? _text(String? v) {
    final t = v?.trim();
    return t == null || t.isEmpty ? null : t;
  }

  Future<T> _guard<T>(Future<T> Function() op) async {
    try {
      return await op();
    } on PostgrestException catch (e) {
      if (e.message.contains('future')) {
        throw const RefuelingFailure(
          'A data do abastecimento não pode estar no futuro.',
        );
      }
      if (e.message.contains('Odometer')) {
        throw const RefuelingFailure(
          'A quilometragem não combina com as datas do histórico.',
        );
      }
      throw RefuelingFailure(
        e.code == '42501'
            ? 'Você não tem permissão para este abastecimento.'
            : 'Revise os dados do abastecimento.',
      );
    } catch (e) {
      if (e is RefuelingFailure) rethrow;
      throw const RefuelingFailure('Não foi possível conectar ao serviço.');
    }
  }
}
