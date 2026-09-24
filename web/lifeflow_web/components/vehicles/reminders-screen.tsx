"use client";

import { useState } from "react";
import { Check, RotateCcw } from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { ConfirmDelete } from "@/components/finance/shared";
import { ReminderDialog } from "@/components/vehicles/reminder-dialog";
import { ListSection, RowActions, UrgencyBadge } from "@/components/vehicles/shared";
import { formatDate } from "@/lib/finance/format";
import { formatOdometer } from "@/lib/vehicles/format";
import { useDeleteReminder, useReminders, useSetReminderCompleted } from "@/lib/vehicles/hooks";
import type { Reminder } from "@/lib/vehicles/api";

/** "faltam 1.200 km · em 12 dias" / "vencido há 3 dias". */
export function reminderRemaining(r: Pick<Reminder, "remaining_km" | "remaining_days">): string {
  const parts: string[] = [];
  if (r.remaining_km !== null) {
    parts.push(
      r.remaining_km > 0
        ? `faltam ${formatOdometer(r.remaining_km)}`
        : r.remaining_km === 0
          ? "na quilometragem"
          : `passou ${formatOdometer(-r.remaining_km)}`,
    );
  }
  if (r.remaining_days !== null) {
    const d = r.remaining_days;
    parts.push(d > 0 ? `em ${d} ${d === 1 ? "dia" : "dias"}` : d === 0 ? "hoje" : `há ${-d} ${d === -1 ? "dia" : "dias"}`);
  }
  return parts.join(" · ");
}

export function RemindersScreen({ vehicleId }: { vehicleId: string }) {
  const reminders = useReminders(vehicleId);
  const complete = useSetReminderCompleted();
  const remove = useDeleteReminder();
  const [creating, setCreating] = useState(false);
  const [editing, setEditing] = useState<Reminder | null>(null);
  const [deleting, setDeleting] = useState<Reminder | null>(null);
  const [toggleError, setToggleError] = useState<string | null>(null);

  // Ativos primeiro, mais urgentes no topo; concluídos por último.
  const rank = { overdue: 0, near: 1, upcoming: 2, completed: 3 } as const;
  const data = [...(reminders.data ?? [])].sort(
    (a, b) => rank[a.visual_status] - rank[b.visual_status],
  );

  async function toggle(r: Reminder) {
    setToggleError(null);
    try {
      await complete.mutateAsync({ id: r.id, completed: r.status !== "completed" });
    } catch (e) {
      setToggleError(e instanceof Error ? e.message : "Não foi possível atualizar o lembrete.");
    }
  }

  return (
    <>
      <ListSection
        title="Lembretes"
        description="Cuidados por quilometragem ou data."
        actionLabel="Novo lembrete"
        onAction={() => setCreating(true)}
        query={reminders}
        isEmpty={data.length === 0}
        emptyTitle="Nenhum lembrete."
        emptyDescription="Crie lembretes para não esquecer trocas e revisões."
        errorMessage="Não foi possível carregar os lembretes."
      >
        {toggleError && (
          <p role="alert" className="px-2 pb-2 text-sm text-critical">
            {toggleError}
          </p>
        )}
        <Table>
          <TableHeader>
            <TableRow className="hover:bg-transparent">
              <TableHead>Lembrete</TableHead>
              <TableHead className="hidden md:table-cell">Meta</TableHead>
              <TableHead>Situação</TableHead>
              <TableHead className="w-36" />
            </TableRow>
          </TableHeader>
          <TableBody>
            {data.map((r) => {
              const done = r.status === "completed";
              return (
                <TableRow key={r.id}>
                  <TableCell className="max-w-72 whitespace-normal">
                    <span className={done ? "font-medium text-muted-foreground line-through" : "font-medium"}>
                      {r.description}
                    </span>
                    {!done && (
                      <span className="mt-0.5 block text-xs text-muted-foreground">
                        {reminderRemaining(r)}
                      </span>
                    )}
                  </TableCell>
                  <TableCell className="hidden text-muted-foreground tabular-nums md:table-cell">
                    {[
                      r.target_odometer !== null && formatOdometer(r.target_odometer),
                      r.target_date && formatDate(r.target_date),
                    ]
                      .filter(Boolean)
                      .join(" · ")}
                  </TableCell>
                  <TableCell>
                    <UrgencyBadge status={r.visual_status} />
                  </TableCell>
                  <TableCell>
                    <div className="flex items-center justify-end">
                      <Button
                        variant="ghost"
                        size="icon-sm"
                        aria-label={done ? `Reabrir ${r.description}` : `Concluir ${r.description}`}
                        title={done ? "Reabrir" : "Marcar como concluído"}
                        onClick={() => void toggle(r)}
                      >
                        {done ? <RotateCcw /> : <Check />}
                      </Button>
                      <RowActions
                        label={r.description}
                        onEdit={() => setEditing(r)}
                        onDelete={() => setDeleting(r)}
                      />
                    </div>
                  </TableCell>
                </TableRow>
              );
            })}
          </TableBody>
        </Table>
      </ListSection>
      <ReminderDialog vehicleId={vehicleId} open={creating} onOpenChange={setCreating} />
      <ReminderDialog
        vehicleId={vehicleId}
        open={editing !== null}
        onOpenChange={(o) => !o && setEditing(null)}
        initial={editing}
      />
      <ConfirmDelete
        open={deleting !== null}
        onOpenChange={(o) => !o && setDeleting(null)}
        title="Excluir lembrete?"
        description={`"${deleting?.description ?? ""}" será removido.`}
        onConfirm={async () => {
          if (deleting) await remove.mutateAsync(deleting.id);
        }}
      />
    </>
  );
}
