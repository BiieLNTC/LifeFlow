import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeflow_app/core/supabase/supabase_provider.dart';
import 'package:lifeflow_app/core/sync/offline_repository_support.dart';
import 'package:lifeflow_app/core/sync/offline_store.dart';
import 'package:lifeflow_app/features/dashboard/domain/dashboard_repository.dart';
import 'package:lifeflow_app/features/dashboard/domain/vehicle_dashboard.dart';
import 'package:lifeflow_app/features/reminders/domain/reminder.dart';
import 'package:lifeflow_app/features/vehicles/domain/vehicle.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => SupabaseDashboardRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(offlineStoreProvider),
  ),
);

class SupabaseDashboardRepository implements DashboardRepository {
  SupabaseDashboardRepository(this.client, OfflineStore store)
    : _offline = OfflineRepositorySupport(client, store);
  final SupabaseClient client;
  final OfflineRepositorySupport _offline;

  @override
  Future<List<VehicleDashboard>> getDashboard() async {
    try {
      final rows = await _offline.readList(
        entityType: 'dashboard',
        parentId: null,
        remote: () async {
          final remote = await client
              .from('vehicle_dashboard')
              .select()
              .order('nickname');
          return [
            for (final row in remote)
              <String, dynamic>{...row, 'id': row['vehicle_id']},
          ];
        },
        sortCached: (a, b) =>
            (a['nickname'] as String).compareTo(b['nickname'] as String),
      );
      return rows.map(_fromJson).toList(growable: false);
    } on PostgrestException catch (error) {
      throw DashboardFailure(
        error.code == '42501'
            ? 'Você não tem permissão para acessar este resumo.'
            : 'Não foi possível carregar o resumo do veículo.',
      );
    } catch (error) {
      if (error is DashboardFailure) rethrow;
      throw const DashboardFailure(
        'Não foi possível conectar ao serviço. Verifique sua internet.',
      );
    }
  }

  VehicleDashboard _fromJson(Map<String, dynamic> json) {
    final reminderId = json['next_reminder_id'] as String?;
    return VehicleDashboard(
      vehicleId: json['vehicle_id'],
      vehicleType: VehicleType.fromDatabase(json['vehicle_type']),
      nickname: json['nickname'],
      brand: json['brand'],
      model: json['model'],
      version: json['version'],
      manufactureYear: json['manufacture_year'],
      modelYear: json['model_year'],
      currentOdometer: json['current_odometer'],
      photoPath: json['photo_path'],
      monthlySpending: _number(json['monthly_spending'])!,
      monthlyConsumptionKmL: _number(json['consumption_km_l']),
      costPerKm: _number(json['cost_per_km']),
      monthlyDistanceKm: json['monthly_distance_km'],
      attentionCount: json['attention_count'],
      nextReminder: reminderId == null
          ? null
          : DashboardReminder(
              id: reminderId,
              description: json['next_reminder_description'],
              urgency: ReminderUrgency.fromDatabase(
                json['next_reminder_status'],
              ),
              targetOdometer: json['next_reminder_odometer'],
              targetDate: json['next_reminder_date'] == null
                  ? null
                  : DateTime.parse(json['next_reminder_date']),
              remainingKm: json['next_reminder_remaining_km'],
              remainingDays: json['next_reminder_remaining_days'],
            ),
    );
  }

  double? _number(Object? value) => switch (value) {
    null => null,
    num number => number.toDouble(),
    String text => double.parse(text),
    _ => throw const FormatException('Número inválido no dashboard.'),
  };
}
