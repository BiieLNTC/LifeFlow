/**
 * Regras puras da central de notificações (view `notification_items`).
 * Sem acesso a dados — reaproveitadas pela tela, pelo badge e pelos testes.
 */

export type NotificationKind =
  | "reminder"
  | "budget"
  | "vehicle_document"
  | "recurring_transaction";

export type NotificationSeverity = "critical" | "warning" | "info";

export type NotificationItem = {
  kind: NotificationKind;
  title: string;
  subtitle: string;
  severity: NotificationSeverity;
  targetType: string;
  targetId: string;
  dueDate: string | null;
  vehicleId: string | null;
};

const severityRank: Record<NotificationSeverity, number> = {
  critical: 0,
  warning: 1,
  info: 2,
};

export const kindLabels: Record<NotificationKind, string> = {
  reminder: "Lembrete",
  budget: "Orçamento",
  vehicle_document: "Documento",
  recurring_transaction: "Recorrência",
};

/** Mais grave primeiro; dentro da mesma gravidade, vencimento mais próximo primeiro. */
export function sortNotifications(items: NotificationItem[]): NotificationItem[] {
  return [...items].sort((a, b) => {
    const bySeverity = severityRank[a.severity] - severityRank[b.severity];
    if (bySeverity !== 0) return bySeverity;
    if (a.dueDate === b.dueDate) return 0;
    if (a.dueDate === null) return 1;
    if (b.dueDate === null) return -1;
    return a.dueDate.localeCompare(b.dueDate);
  });
}

/** Rota web de destino; `null` quando o item não tem para onde ir (ex.: veículo ausente). */
export function notificationHref(item: NotificationItem): string | null {
  switch (item.kind) {
    case "reminder":
      return item.vehicleId ? `/vehicles/${item.vehicleId}/reminders` : null;
    case "vehicle_document":
      return item.vehicleId ? `/vehicles/${item.vehicleId}/documents` : null;
    case "budget":
      return "/finance/budgets";
    // A geração acontece ao abrir a visão geral de Finanças (ROADMAP §1.5).
    case "recurring_transaction":
      return "/finance";
  }
}

/** Severidade mais alta do conjunto — define a cor do badge. */
export function highestSeverity(items: NotificationItem[]): NotificationSeverity | null {
  let best: NotificationSeverity | null = null;
  for (const item of items) {
    if (best === null || severityRank[item.severity] < severityRank[best]) {
      best = item.severity;
    }
  }
  return best;
}
