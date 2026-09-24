import type { PostgrestError, SupabaseClient } from "@supabase/supabase-js";
import type { Database } from "@/lib/supabase/database.types";
import {
  sortNotifications,
  type NotificationItem,
  type NotificationKind,
  type NotificationSeverity,
} from "@/lib/notifications/model";

type Db = SupabaseClient<Database>;

/** Erro com mensagem já em pt-BR, pronta para exibir. */
export class NotificationError extends Error {}

const kinds: NotificationKind[] = [
  "reminder",
  "budget",
  "vehicle_document",
  "recurring_transaction",
];
const severities: NotificationSeverity[] = ["critical", "warning", "info"];

/** Central unificada, já ordenada (mais grave primeiro). Só leitura — a view é `security_invoker`. */
export async function listNotifications(db: Db): Promise<NotificationItem[]> {
  let result: { data: unknown[] | null; error: PostgrestError | null };
  try {
    result = await db.from("notification_items").select("*");
  } catch {
    throw new NotificationError("Não foi possível conectar ao serviço.");
  }
  if (result.error || !result.data) {
    throw new NotificationError("Não foi possível carregar as notificações.");
  }

  const rows = result.data as Database["public"]["Views"]["notification_items"]["Row"][];
  const items = rows.flatMap((row): NotificationItem[] => {
    // Linha desconhecida (view evoluiu antes do client) é ignorada em vez de quebrar a tela.
    if (
      !kinds.includes(row.kind as NotificationKind) ||
      !severities.includes(row.severity as NotificationSeverity) ||
      !row.target_id
    ) {
      return [];
    }
    return [
      {
        kind: row.kind as NotificationKind,
        title: row.title ?? "",
        subtitle: row.subtitle ?? "",
        severity: row.severity as NotificationSeverity,
        targetType: row.target_type ?? "",
        targetId: row.target_id,
        dueDate: row.due_date,
        vehicleId: row.vehicle_id,
      },
    ];
  });
  return sortNotifications(items);
}
