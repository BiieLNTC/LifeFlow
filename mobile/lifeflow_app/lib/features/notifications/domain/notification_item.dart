enum NotificationKind {
  reminder('reminder', 'Lembrete'),
  budget('budget', 'Orçamento'),
  vehicleDocument('vehicle_document', 'Documento'),
  recurringTransaction('recurring_transaction', 'Recorrência');

  const NotificationKind(this.databaseValue, this.label);
  final String databaseValue;
  final String label;

  static NotificationKind? tryFromDatabase(String value) {
    for (final kind in values) {
      if (kind.databaseValue == value) return kind;
    }
    return null;
  }
}

/// Ordem de declaração = ordem de gravidade (mais grave primeiro).
enum NotificationSeverity {
  critical('critical'),
  warning('warning'),
  info('info');

  const NotificationSeverity(this.databaseValue);
  final String databaseValue;

  static NotificationSeverity? tryFromDatabase(String value) {
    for (final severity in values) {
      if (severity.databaseValue == value) return severity;
    }
    return null;
  }
}

/// Linha da view `notification_items` (central de notificações).
class NotificationItem {
  const NotificationItem({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.severity,
    required this.targetId,
    this.dueDate,
    this.vehicleId,
  });

  final NotificationKind kind;
  final String title;
  final String subtitle;
  final NotificationSeverity severity;
  final String targetId;
  final DateTime? dueDate;
  final String? vehicleId;

  /// Rota de destino; `null` quando não há para onde ir (ex.: veículo ausente).
  ///
  /// O Flutter ainda não tem tela de documentos (só o web) — o documento leva ao
  /// veículo. A recorrência leva a Finanças, que gera as ocorrências ao abrir
  /// (ROADMAP §1.5).
  String? get location => switch (kind) {
    NotificationKind.reminder =>
      vehicleId == null ? null : '/vehicles/$vehicleId/reminders',
    NotificationKind.vehicleDocument =>
      vehicleId == null ? null : '/vehicles/$vehicleId',
    NotificationKind.budget || NotificationKind.recurringTransaction =>
      '/finance',
  };
}

/// Mais grave primeiro; na mesma gravidade, o vencimento mais próximo primeiro
/// (sem vencimento por último). Mesma regra do web.
List<NotificationItem> sortNotifications(Iterable<NotificationItem> items) {
  final sorted = items.toList();
  sorted.sort((a, b) {
    final bySeverity = a.severity.index.compareTo(b.severity.index);
    if (bySeverity != 0) return bySeverity;
    final da = a.dueDate;
    final db = b.dueDate;
    if (da == null && db == null) return 0;
    if (da == null) return 1;
    if (db == null) return -1;
    return da.compareTo(db);
  });
  return sorted;
}
