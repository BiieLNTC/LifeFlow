"use client";

import { useState } from "react";
import { Eye } from "lucide-react";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { ConfirmDelete, FormError } from "@/components/finance/shared";
import { MaintenanceDetailDialog } from "@/components/vehicles/maintenance-detail-dialog";
import { MaintenanceDialog } from "@/components/vehicles/maintenance-dialog";
import { ListSection, RowActions } from "@/components/vehicles/shared";
import { formatCurrency, formatDate } from "@/lib/finance/format";
import { formatOdometer } from "@/lib/vehicles/format";
import {
  useCreateRemindersFromMaintenance,
  useDeleteMaintenance,
  useMaintenances,
  useVehicle,
} from "@/lib/vehicles/hooks";
import { maintenanceTypeLabels } from "@/lib/vehicles/options";
import type { Maintenance, ReminderSuggestion } from "@/lib/vehicles/api";
import type { MaintenanceValues } from "@/lib/vehicles/schemas";

type ReminderOffer = { maintenanceId: string; suggestions: ReminderSuggestion[] };

/** Itens que definiram "próxima troca" viram sugestões de lembrete. */
function suggestionsFrom(values: MaintenanceValues): ReminderSuggestion[] {
  return values.items
    .filter((i) => i.nextOdometer.trim() !== "" || i.nextDate !== "")
    .map((i) => ({
      description: i.description.trim(),
      targetOdometer: i.nextOdometer,
      targetDate: i.nextDate,
    }));
}

export function MaintenancesScreen({ vehicleId }: { vehicleId: string }) {
  const maintenances = useMaintenances(vehicleId);
  const vehicle = useVehicle(vehicleId);
  const remove = useDeleteMaintenance();
  const createReminders = useCreateRemindersFromMaintenance();
  const [creating, setCreating] = useState(false);
  const [editing, setEditing] = useState<Maintenance | null>(null);
  const [viewing, setViewing] = useState<Maintenance | null>(null);
  const [deleting, setDeleting] = useState<Maintenance | null>(null);
  const [offer, setOffer] = useState<ReminderOffer | null>(null);
  const [offerError, setOfferError] = useState<string | null>(null);
  const data = maintenances.data ?? [];

  function onSaved(maintenanceId: string, values: MaintenanceValues, isNew: boolean) {
    const suggestions = suggestionsFrom(values);
    if (isNew && suggestions.length > 0) setOffer({ maintenanceId, suggestions });
  }

  async function acceptOffer() {
    if (!offer) return;
    setOfferError(null);
    try {
      await createReminders.mutateAsync({ vehicleId, ...offer });
      setOffer(null);
    } catch (e) {
      setOfferError(
        `A manutenção foi salva, mas ${(e instanceof Error ? e.message : "não foi possível criar os lembretes.").toLowerCase()}`,
      );
    }
  }

  return (
    <>
      <ListSection
        title="Manutenções"
        description="Serviços, peças e revisões."
        actionLabel="Nova manutenção"
        onAction={() => setCreating(true)}
        query={maintenances}
        isEmpty={data.length === 0}
        emptyTitle="Nenhuma manutenção registrada."
        emptyDescription="Registre serviços e peças para acompanhar custos e próximas trocas."
        errorMessage="Não foi possível carregar as manutenções."
      >
        <Table>
          <TableHeader>
            <TableRow className="hover:bg-transparent">
              <TableHead className="w-28">Data</TableHead>
              <TableHead>Serviço</TableHead>
              <TableHead className="hidden md:table-cell">Quilometragem</TableHead>
              <TableHead className="text-right">Total</TableHead>
              <TableHead className="w-32" />
            </TableRow>
          </TableHeader>
          <TableBody>
            {data.map((m) => {
              const first = m.maintenance_items[0]?.description ?? "Manutenção";
              const extra = m.maintenance_items.length - 1;
              return (
                <TableRow key={m.id}>
                  <TableCell className="text-muted-foreground">{formatDate(m.maintenance_date)}</TableCell>
                  <TableCell className="max-w-64 whitespace-normal">
                    <div className="flex flex-wrap items-center gap-2">
                      <span className="font-medium">
                        {first}
                        {extra > 0 && ` + ${extra} ${extra === 1 ? "item" : "itens"}`}
                      </span>
                      <Badge variant="secondary">
                        {maintenanceTypeLabels[m.maintenance_type as keyof typeof maintenanceTypeLabels] ??
                          m.maintenance_type}
                      </Badge>
                    </div>
                    {m.workshop && (
                      <span className="block text-xs text-muted-foreground">{m.workshop}</span>
                    )}
                  </TableCell>
                  <TableCell className="hidden text-muted-foreground tabular-nums md:table-cell">
                    {formatOdometer(m.odometer)}
                  </TableCell>
                  <TableCell className="text-right font-medium tabular-nums">
                    {formatCurrency(m.total_amount)}
                  </TableCell>
                  <TableCell>
                    <div className="flex items-center justify-end">
                      <Button
                        variant="ghost"
                        size="icon-sm"
                        aria-label={`Ver detalhes da manutenção de ${formatDate(m.maintenance_date)}`}
                        onClick={() => setViewing(m)}
                      >
                        <Eye />
                      </Button>
                      <RowActions
                        label={`manutenção de ${formatDate(m.maintenance_date)}`}
                        onEdit={() => setEditing(m)}
                        onDelete={() => setDeleting(m)}
                      />
                    </div>
                  </TableCell>
                </TableRow>
              );
            })}
          </TableBody>
        </Table>
      </ListSection>

      <MaintenanceDialog
        vehicleId={vehicleId}
        open={creating}
        onOpenChange={setCreating}
        defaultOdometer={vehicle.data?.current_odometer}
        onSaved={onSaved}
      />
      <MaintenanceDialog
        vehicleId={vehicleId}
        open={editing !== null}
        onOpenChange={(o) => !o && setEditing(null)}
        initial={editing}
        onSaved={onSaved}
      />
      <MaintenanceDetailDialog
        maintenance={viewing}
        onOpenChange={(o) => !o && setViewing(null)}
      />
      <ConfirmDelete
        open={deleting !== null}
        onOpenChange={(o) => !o && setDeleting(null)}
        title="Excluir manutenção?"
        description="A manutenção será removida, junto com a transação gerada em Finanças."
        onConfirm={async () => {
          if (deleting) await remove.mutateAsync(deleting.id);
        }}
      />
      <AlertDialog
        open={offer !== null}
        onOpenChange={(o) => {
          if (!o && !createReminders.isPending) {
            setOffer(null);
            setOfferError(null);
          }
        }}
      >
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>
              {offer?.suggestions.length === 1 ? "Criar lembrete?" : "Criar lembretes?"}
            </AlertDialogTitle>
            <AlertDialogDescription>
              {offer?.suggestions.length === 1
                ? `Quer acompanhar a próxima troca de ${offer.suggestions[0].description}?`
                : `Quer acompanhar as próximas trocas dos ${offer?.suggestions.length} itens?`}
            </AlertDialogDescription>
          </AlertDialogHeader>
          <FormError message={offerError} />
          <AlertDialogFooter>
            <AlertDialogCancel disabled={createReminders.isPending}>Agora não</AlertDialogCancel>
            <AlertDialogAction
              disabled={createReminders.isPending}
              onClick={(e) => {
                // Mantém o diálogo aberto se a criação falhar.
                e.preventDefault();
                void acceptOffer();
              }}
            >
              Criar
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  );
}
