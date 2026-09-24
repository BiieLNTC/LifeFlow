import { describe, expect, it } from "vitest";
import {
  highestSeverity,
  notificationHref,
  sortNotifications,
  type NotificationItem,
} from "@/lib/notifications/model";

const base: NotificationItem = {
  kind: "reminder",
  title: "Troca de óleo",
  subtitle: "Vencido",
  severity: "critical",
  targetType: "reminder",
  targetId: "r1",
  dueDate: "2026-09-10",
  vehicleId: "v1",
};

describe("sortNotifications", () => {
  it("põe o mais grave primeiro e, na mesma gravidade, o vencimento mais próximo", () => {
    const items: NotificationItem[] = [
      { ...base, targetId: "info", severity: "info", dueDate: "2026-09-01" },
      { ...base, targetId: "warn-late", severity: "warning", dueDate: "2026-10-05" },
      { ...base, targetId: "crit", severity: "critical", dueDate: "2026-09-20" },
      { ...base, targetId: "warn-soon", severity: "warning", dueDate: "2026-09-25" },
      { ...base, targetId: "warn-none", severity: "warning", dueDate: null },
    ];
    expect(sortNotifications(items).map((i) => i.targetId)).toEqual([
      "crit",
      "warn-soon",
      "warn-late",
      "warn-none",
      "info",
    ]);
  });

  it("não altera a lista original", () => {
    const items = [
      { ...base, targetId: "b", severity: "info" as const },
      { ...base, targetId: "a" },
    ];
    sortNotifications(items);
    expect(items[0].targetId).toBe("b");
  });
});

describe("notificationHref", () => {
  it("leva lembretes e documentos à aba do veículo", () => {
    expect(notificationHref(base)).toBe("/vehicles/v1/reminders");
    expect(notificationHref({ ...base, kind: "vehicle_document" })).toBe(
      "/vehicles/v1/documents",
    );
  });

  it("não tem destino quando falta o veículo", () => {
    expect(notificationHref({ ...base, vehicleId: null })).toBeNull();
  });

  it("leva orçamentos à gestão e recorrências à visão geral de Finanças", () => {
    expect(notificationHref({ ...base, kind: "budget", vehicleId: null })).toBe("/finance/budgets");
    expect(notificationHref({ ...base, kind: "recurring_transaction", vehicleId: null })).toBe(
      "/finance",
    );
  });
});

describe("highestSeverity", () => {
  it("devolve a pior severidade ou null para lista vazia", () => {
    expect(highestSeverity([])).toBeNull();
    expect(
      highestSeverity([
        { ...base, severity: "info" },
        { ...base, severity: "warning" },
      ]),
    ).toBe("warning");
  });
});
