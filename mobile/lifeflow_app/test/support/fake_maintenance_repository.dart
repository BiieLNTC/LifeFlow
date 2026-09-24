import 'package:lifeflow_app/features/maintenance/domain/maintenance.dart';
import 'package:lifeflow_app/features/maintenance/domain/maintenance_repository.dart';

class FakeMaintenanceRepository implements MaintenanceRepository {
  FakeMaintenanceRepository({List<Maintenance> maintenances = const []})
    : _items = [...maintenances];

  List<Maintenance> _items;

  @override
  Future<List<Maintenance>> getMaintenances(String vehicleId) async =>
      _items.where((item) => item.vehicleId == vehicleId).toList();

  @override
  Future<Maintenance> getMaintenance(String id) async =>
      _items.firstWhere((item) => item.id == id);

  @override
  Future<Maintenance> saveMaintenance(String id, MaintenanceDraft draft) async {
    final now = DateTime.utc(2026, 9, 20);
    final maintenance = Maintenance(
      id: id,
      vehicleId: draft.vehicleId,
      date: draft.date,
      odometer: draft.odometer,
      type: draft.type,
      workshop: draft.workshop,
      notes: draft.notes,
      totalAmount: draft.items.fold(
        0,
        (sum, item) => sum + item.partAmount + item.laborAmount,
      ),
      items: [
        for (final item in draft.items)
          MaintenanceItem(
            id: item.id,
            category: item.category,
            description: item.description,
            partAmount: item.partAmount,
            laborAmount: item.laborAmount,
            nextReplacementOdometer: item.nextReplacementOdometer,
            nextReplacementDate: item.nextReplacementDate,
          ),
      ],
      createdAt: now,
      updatedAt: now,
    );
    _items = [maintenance, ..._items.where((item) => item.id != id)];
    return maintenance;
  }

  @override
  Future<void> deleteMaintenance(String id) async {
    _items = _items.where((item) => item.id != id).toList();
  }
}

Maintenance fakeMaintenance({String id = 'maintenance-id'}) {
  final now = DateTime.utc(2026, 9, 20);
  return Maintenance(
    id: id,
    vehicleId: 'vehicle-id',
    date: now,
    odometer: 127340,
    type: MaintenanceType.preventive,
    totalAmount: 290,
    items: const [
      MaintenanceItem(
        id: 'item-id',
        category: MaintenanceCategory.oil,
        description: 'Troca de óleo',
        partAmount: 220,
        laborAmount: 70,
      ),
    ],
    createdAt: now,
    updatedAt: now,
  );
}
