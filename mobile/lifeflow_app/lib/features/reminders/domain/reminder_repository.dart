import 'package:lifeflow_app/features/reminders/domain/reminder.dart';

abstract interface class ReminderRepository {
  Future<List<Reminder>> getReminders(String vehicleId);
  Future<Reminder> getReminder(String id);
  Future<Reminder> saveReminder(String id, ReminderDraft draft);
  Future<Reminder> setCompleted(String id, {required bool completed});
  Future<void> deleteReminder(String id);
}

class ReminderFailure implements Exception {
  const ReminderFailure(this.message);
  final String message;
}
