import 'package:lifeflow_app/features/notifications/domain/notification_item.dart';

class NotificationFailure implements Exception {
  const NotificationFailure(this.message);
  final String message;
}

abstract interface class NotificationRepository {
  /// Já ordenada: mais grave primeiro.
  Future<List<NotificationItem>> list();
}
