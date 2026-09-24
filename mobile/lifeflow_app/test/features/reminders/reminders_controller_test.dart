import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeflow_app/features/reminders/data/supabase_reminder_repository.dart';
import 'package:lifeflow_app/features/reminders/domain/reminder.dart';
import 'package:lifeflow_app/features/reminders/domain/reminder_repository.dart';
import 'package:lifeflow_app/features/reminders/presentation/reminders_controller.dart';

void main() {
  test('cria, edita, conclui, reabre e remove lembrete', () async {
    final repository = _FakeReminderRepository();
    final container = ProviderContainer(
      overrides: [reminderRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      remindersProvider('vehicle-id'),
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    await container.read(remindersProvider('vehicle-id').future);
    final controller = container.read(
      remindersProvider('vehicle-id').notifier,
    );

    final created = await controller.create(_draft('Troca de óleo'));
    expect(created.description, 'Troca de óleo');

    final updated = await controller.updateReminder(
      created.id,
      _draft('Troca de óleo e filtro'),
    );
    expect(updated.description, 'Troca de óleo e filtro');

    await controller.setCompleted(updated, completed: true);
    expect(
      container.read(remindersProvider('vehicle-id')).value?.single.status,
      ReminderStatus.completed,
    );

    await controller.setCompleted(repository.value!, completed: false);
    expect(repository.value?.status, ReminderStatus.active);

    await controller.delete(created.id);
    expect(container.read(remindersProvider('vehicle-id')).value, isEmpty);
  });
}

ReminderDraft _draft(String description) => ReminderDraft(
  vehicleId: 'vehicle-id',
  description: description,
  targetOdometer: 130000,
);

class _FakeReminderRepository implements ReminderRepository {
  Reminder? value;

  @override
  Future<List<Reminder>> getReminders(String vehicleId) async =>
      value == null ? [] : [value!];

  @override
  Future<Reminder> getReminder(String id) async => value!;

  @override
  Future<Reminder> saveReminder(String id, ReminderDraft draft) async {
    value = _reminder(
      id: id,
      description: draft.description,
      status: draft.status,
    );
    return value!;
  }

  @override
  Future<Reminder> setCompleted(
    String id, {
    required bool completed,
  }) async {
    value = _reminder(
      id: id,
      description: value!.description,
      status: completed ? ReminderStatus.completed : ReminderStatus.active,
    );
    return value!;
  }

  @override
  Future<void> deleteReminder(String id) async => value = null;

  Reminder _reminder({
    required String id,
    required String description,
    required ReminderStatus status,
  }) => Reminder(
    id: id,
    vehicleId: 'vehicle-id',
    description: description,
    targetOdometer: 130000,
    status: status,
    urgency: status == ReminderStatus.completed
        ? ReminderUrgency.completed
        : ReminderUrgency.near,
    currentOdometer: 129500,
    remainingKm: 500,
    createdAt: DateTime.utc(2026, 9, 20),
    updatedAt: DateTime.utc(2026, 9, 20),
  );
}
