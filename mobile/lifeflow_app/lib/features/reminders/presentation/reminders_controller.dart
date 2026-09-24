import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeflow_app/features/reminders/data/supabase_reminder_repository.dart';
import 'package:lifeflow_app/features/reminders/domain/reminder.dart';
import 'package:uuid/uuid.dart';

final remindersProvider =
    AsyncNotifierProvider.family<RemindersController, List<Reminder>, String>(
      RemindersController.new,
    );

final reminderDetailsProvider = FutureProvider.family<Reminder, String>(
  (ref, id) => ref.watch(reminderRepositoryProvider).getReminder(id),
);

class RemindersController extends AsyncNotifier<List<Reminder>> {
  RemindersController(this.vehicleId);
  final String vehicleId;
  final _uuid = const Uuid();

  @override
  Future<List<Reminder>> build() =>
      ref.watch(reminderRepositoryProvider).getReminders(vehicleId);

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(reminderRepositoryProvider).getReminders(vehicleId),
    );
  }

  Future<Reminder> create(ReminderDraft draft) async {
    final reminder = await ref
        .read(reminderRepositoryProvider)
        .saveReminder(_uuid.v7(), draft);
    state = AsyncData([...?state.value, reminder]);
    return reminder;
  }

  Future<Reminder> updateReminder(String id, ReminderDraft draft) async {
    final reminder = await ref
        .read(reminderRepositoryProvider)
        .saveReminder(id, draft);
    _replace(reminder);
    ref.invalidate(reminderDetailsProvider(id));
    return reminder;
  }

  Future<void> setCompleted(
    Reminder reminder, {
    required bool completed,
  }) async {
    final updated = await ref
        .read(reminderRepositoryProvider)
        .setCompleted(reminder.id, completed: completed);
    _replace(updated);
    ref.invalidate(reminderDetailsProvider(reminder.id));
  }

  Future<void> delete(String id) async {
    await ref.read(reminderRepositoryProvider).deleteReminder(id);
    state = AsyncData(
      (state.value ?? const <Reminder>[])
          .where((item) => item.id != id)
          .toList(),
    );
    ref.invalidate(reminderDetailsProvider(id));
  }

  void _replace(Reminder reminder) {
    state = AsyncData([
      for (final item in state.value ?? const <Reminder>[])
        if (item.id == reminder.id) reminder else item,
    ]);
  }
}
