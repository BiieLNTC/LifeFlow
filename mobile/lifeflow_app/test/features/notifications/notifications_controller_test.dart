import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeflow_app/features/notifications/data/supabase_notification_repository.dart';
import 'package:lifeflow_app/features/notifications/domain/notification_item.dart';
import 'package:lifeflow_app/features/notifications/domain/notification_repository.dart';
import 'package:lifeflow_app/features/notifications/presentation/notifications_controller.dart';

void main() {
  test('sortNotifications põe o mais grave e o vencimento mais próximo primeiro', () {
    final sorted = sortNotifications([
      _item('info', NotificationSeverity.info, DateTime(2026, 9, 1)),
      _item('warn-late', NotificationSeverity.warning, DateTime(2026, 10, 5)),
      _item('crit', NotificationSeverity.critical, DateTime(2026, 9, 20)),
      _item('warn-soon', NotificationSeverity.warning, DateTime(2026, 9, 25)),
      _item('warn-none', NotificationSeverity.warning, null),
    ]);
    expect(sorted.map((i) => i.targetId), [
      'crit',
      'warn-soon',
      'warn-late',
      'warn-none',
      'info',
    ]);
  });

  group('location', () {
    test('lembrete leva à lista de lembretes do veículo', () {
      final item = _item('r', NotificationSeverity.critical, null);
      expect(item.location, '/vehicles/vehicle-id/reminders');
    });

    test('documento leva ao veículo (não há tela de documentos no app)', () {
      final item = _item(
        'd',
        NotificationSeverity.warning,
        null,
        kind: NotificationKind.vehicleDocument,
      );
      expect(item.location, '/vehicles/vehicle-id');
    });

    test('sem veículo não há destino; orçamento e recorrência vão a Finanças', () {
      expect(
        _item('r', NotificationSeverity.critical, null, vehicleId: null)
            .location,
        isNull,
      );
      expect(
        _item(
          'b',
          NotificationSeverity.warning,
          null,
          kind: NotificationKind.budget,
          vehicleId: null,
        ).location,
        '/finance',
      );
      expect(
        _item(
          'x',
          NotificationSeverity.info,
          null,
          kind: NotificationKind.recurringTransaction,
          vehicleId: null,
        ).location,
        '/finance',
      );
    });
  });

  test('contagem e pior severidade alimentam o badge', () async {
    final container = ProviderContainer(
      overrides: [
        notificationRepositoryProvider.overrideWithValue(
          _Fake([
            _item('crit', NotificationSeverity.critical, null),
            _item('info', NotificationSeverity.info, null),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      notificationsProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await container.read(notificationsProvider.future);
    expect(container.read(notificationCountProvider), 2);
    expect(
      container.read(notificationTopSeverityProvider),
      NotificationSeverity.critical,
    );
  });

  test('o badge zera em erro em vez de alarmar em falso', () async {
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        notificationRepositoryProvider.overrideWithValue(_Fake(null)),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      notificationsProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await expectLater(
      container.read(notificationsProvider.future),
      throwsA(isA<NotificationFailure>()),
    );
    expect(container.read(notificationCountProvider), 0);
    expect(container.read(notificationTopSeverityProvider), isNull);
  });
}

NotificationItem _item(
  String id,
  NotificationSeverity severity,
  DateTime? due, {
  NotificationKind kind = NotificationKind.reminder,
  String? vehicleId = 'vehicle-id',
}) => NotificationItem(
  kind: kind,
  title: id,
  subtitle: 'Vencido',
  severity: severity,
  targetId: id,
  dueDate: due,
  vehicleId: vehicleId,
);

class _Fake implements NotificationRepository {
  _Fake(this.items);
  final List<NotificationItem>? items;

  @override
  Future<List<NotificationItem>> list() async {
    final items = this.items;
    if (items == null) throw const NotificationFailure('falhou');
    return sortNotifications(items);
  }
}
