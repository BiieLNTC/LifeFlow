import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeflow_app/core/supabase/supabase_provider.dart';
import 'package:lifeflow_app/core/sync/offline_repository_support.dart';
import 'package:lifeflow_app/core/sync/offline_store.dart';
import 'package:lifeflow_app/features/maintenance/domain/maintenance.dart';
import 'package:lifeflow_app/features/maintenance/domain/maintenance_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseMaintenanceRepository(
    client,
    OfflineRepositorySupport(client, ref.watch(offlineStoreProvider)),
  );
});

class SupabaseMaintenanceRepository implements MaintenanceRepository {
  SupabaseMaintenanceRepository(this._client, this._offline);
  final SupabaseClient _client;
  final OfflineRepositorySupport _offline;

  static const _selection = '*, maintenance_items(*)';

  @override
  Future<List<Maintenance>> getMaintenances(String vehicleId) {
    return _guard(() async {
      final rows = await _offline.readList(
        entityType: 'maintenance',
        parentId: vehicleId,
        remote: () async =>
            (await _client
                    .from('maintenances')
                    .select(_selection)
                    .eq('vehicle_id', vehicleId)
                    .isFilter('deleted_at', null)
                    .order('maintenance_date', ascending: false)
                    .order('created_at', ascending: false))
                .cast<Map<String, dynamic>>(),
      );
      final result = rows.map(_fromJson).toList();
      result.sort((a, b) => b.date.compareTo(a.date));
      return result;
    });
  }

  @override
  Future<Maintenance> getMaintenance(String id) {
    return _guard(() async {
      final row = await _offline.readOne(
        entityType: 'maintenance',
        recordId: id,
        remote: () => _fetchRemote(id),
      );
      return _fromJson(row);
    });
  }

  @override
  Future<Maintenance> saveMaintenance(String id, MaintenanceDraft draft) {
    return _guard(() async {
      final payload = {
        'p_id': id,
        'p_vehicle_id': draft.vehicleId,
        'p_maintenance_date': _date(draft.date),
        'p_odometer': draft.odometer,
        'p_maintenance_type': draft.type.databaseValue,
        'p_workshop': _optionalText(draft.workshop),
        'p_notes': _optionalText(draft.notes),
        'p_items': [for (final item in draft.items) _itemToJson(item)],
      };
      final previous = await _offline.store.readRecord(
        userId: _offline.userId,
        entityType: 'maintenance',
        recordId: id,
      );
      final row = await _offline.save(
        entityType: 'maintenance',
        recordId: id,
        parentId: draft.vehicleId,
        localRecord: _localJson(id, draft, previous: previous),
        remotePayload: payload,
        remote: () async {
          await _client.rpc('save_maintenance', params: payload);
          return _fetchRemote(id);
        },
      );
      await _offline.store.advanceVehicleOdometer(
        userId: _offline.userId,
        vehicleId: draft.vehicleId,
        odometer: draft.odometer,
      );
      return _fromJson(row);
    });
  }

  @override
  Future<void> deleteMaintenance(String id) {
    return _guard(() async {
      final previous = await _offline.store.readRecord(
        userId: _offline.userId,
        entityType: 'maintenance',
        recordId: id,
      );
      await _offline.delete(
        entityType: 'maintenance',
        recordId: id,
        parentId: previous?['vehicle_id'] as String?,
        remote: () async {
          await _client
              .from('maintenances')
              .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
              .eq('id', id)
              .select('id')
              .single();
        },
      );
    });
  }

  Map<String, Object?> _itemToJson(MaintenanceItemDraft item) => {
    'id': item.id,
    'category': item.category.databaseValue,
    'description': item.description.trim(),
    'part_amount': item.partAmount,
    'labor_amount': item.laborAmount,
    'next_replacement_odometer': item.nextReplacementOdometer,
    'next_replacement_date': item.nextReplacementDate == null
        ? null
        : _date(item.nextReplacementDate!),
  };

  Future<Map<String, dynamic>> _fetchRemote(String id) => _client
      .from('maintenances')
      .select(_selection)
      .eq('id', id)
      .isFilter('deleted_at', null)
      .single();

  Map<String, dynamic> _localJson(
    String id,
    MaintenanceDraft draft, {
    Map<String, dynamic>? previous,
  }) {
    final now = DateTime.now().toUtc().toIso8601String();
    return {
      'id': id,
      'vehicle_id': draft.vehicleId,
      'maintenance_date': _date(draft.date),
      'odometer': draft.odometer,
      'maintenance_type': draft.type.databaseValue,
      'workshop': _optionalText(draft.workshop),
      'notes': _optionalText(draft.notes),
      'total_amount': draft.items.fold<double>(
        0,
        (total, item) => total + item.partAmount + item.laborAmount,
      ),
      'maintenance_items': [
        for (final item in draft.items)
          {'maintenance_id': id, ..._itemToJson(item)},
      ],
      'created_at': previous?['created_at'] ?? now,
      'updated_at': now,
      'deleted_at': null,
    };
  }

  Maintenance _fromJson(Map<String, dynamic> json) {
    final itemRows = (json['maintenance_items'] as List? ?? const []);
    final items = itemRows
        .cast<Map<String, dynamic>>()
        .map(_itemFromJson)
        .toList(growable: false);
    return Maintenance(
      id: json['id'] as String,
      vehicleId: json['vehicle_id'] as String,
      date: DateTime.parse(json['maintenance_date'] as String),
      odometer: json['odometer'] as int,
      type: MaintenanceType.fromDatabase(json['maintenance_type'] as String),
      workshop: json['workshop'] as String?,
      notes: json['notes'] as String?,
      totalAmount: _decimal(json['total_amount']),
      items: items,
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toUtc(),
    );
  }

  MaintenanceItem _itemFromJson(Map<String, dynamic> json) => MaintenanceItem(
    id: json['id'] as String,
    category: MaintenanceCategory.fromDatabase(json['category'] as String),
    description: json['description'] as String,
    partAmount: _decimal(json['part_amount']),
    laborAmount: _decimal(json['labor_amount']),
    nextReplacementOdometer: json['next_replacement_odometer'] as int?,
    nextReplacementDate: json['next_replacement_date'] == null
        ? null
        : DateTime.parse(json['next_replacement_date'] as String),
  );

  String _date(DateTime value) => value.toIso8601String().split('T').first;
  String? _optionalText(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  double _decimal(Object? value) => switch (value) {
    num number => number.toDouble(),
    String text => double.parse(text),
    _ => throw const FormatException('Valor monetário inválido.'),
  };

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on PostgrestException catch (error) {
      throw MaintenanceFailure(_messageFor(error));
    } catch (error) {
      if (error is MaintenanceFailure) rethrow;
      throw const MaintenanceFailure(
        'Não foi possível conectar ao serviço. Confira sua internet.',
      );
    }
  }

  String _messageFor(PostgrestException error) {
    if (error.message.contains('future')) {
      return 'A data da manutenção não pode estar no futuro.';
    }
    if (error.message.contains('Odometer')) {
      return 'A quilometragem não combina com as datas do histórico.';
    }
    return switch (error.code) {
      '23514' ||
      '22001' ||
      '22P02' => 'Revise os dados da manutenção e tente novamente.',
      '42501' => 'Você não tem permissão para acessar esta manutenção.',
      'PGRST116' => 'Manutenção não encontrada ou sem permissão de acesso.',
      _ => 'Não foi possível salvar a manutenção. Tente novamente.',
    };
  }
}
