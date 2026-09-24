"use client";

import { useState } from "react";
import { Flag } from "lucide-react";
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
import { ConfirmDelete } from "@/components/finance/shared";
import { ListSection, RowActions } from "@/components/vehicles/shared";
import { TripDialog, type TripMode } from "@/components/vehicles/trip-dialog";
import { formatDateTime, formatOdometer } from "@/lib/vehicles/format";
import { useDeleteTrip, useTrips, useVehicle } from "@/lib/vehicles/hooks";
import type { Trip } from "@/lib/vehicles/api";

type Dialog = { mode: TripMode; trip: Trip | null } | null;

export function TripsScreen({ vehicleId }: { vehicleId: string }) {
  const trips = useTrips(vehicleId);
  const vehicle = useVehicle(vehicleId);
  const remove = useDeleteTrip();
  const [dialog, setDialog] = useState<Dialog>(null);
  const [deleting, setDeleting] = useState<Trip | null>(null);
  const data = trips.data ?? [];

  return (
    <>
      <ListSection
        title="Diário de viagens"
        description="Registre saídas e chegadas para acompanhar a distância percorrida."
        actionLabel="Iniciar viagem"
        onAction={() => setDialog({ mode: "start", trip: null })}
        query={trips}
        isEmpty={data.length === 0}
        emptyTitle="Nenhuma viagem registrada."
        emptyDescription="Inicie uma viagem ao sair e encerre ao chegar."
        errorMessage="Não foi possível carregar as viagens."
      >
        <Table>
          <TableHeader>
            <TableRow className="hover:bg-transparent">
              <TableHead>Viagem</TableHead>
              <TableHead className="hidden md:table-cell">Quilometragem</TableHead>
              <TableHead className="text-right">Distância</TableHead>
              <TableHead className="w-32" />
            </TableRow>
          </TableHeader>
          <TableBody>
            {data.map((t) => {
              const active = t.ended_at === null;
              return (
                <TableRow key={t.id}>
                  <TableCell className="whitespace-normal">
                    <div className="flex flex-wrap items-center gap-2">
                      <span className="font-medium">{t.purpose ?? "Sem motivo"}</span>
                      {active && (
                        <Badge variant="ghost" className="bg-primary/10 text-primary">
                          Em andamento
                        </Badge>
                      )}
                    </div>
                    <span className="block text-xs text-muted-foreground">
                      {formatDateTime(t.started_at)}
                      {t.ended_at && ` → ${formatDateTime(t.ended_at)}`}
                    </span>
                  </TableCell>
                  <TableCell className="hidden text-muted-foreground tabular-nums md:table-cell">
                    {formatOdometer(t.start_odometer)}
                    {t.end_odometer !== null && ` → ${formatOdometer(t.end_odometer)}`}
                  </TableCell>
                  <TableCell className="text-right font-medium tabular-nums">
                    {t.end_odometer !== null ? formatOdometer(t.end_odometer - t.start_odometer) : "—"}
                  </TableCell>
                  <TableCell>
                    <div className="flex items-center justify-end">
                      {active && (
                        <Button
                          variant="ghost"
                          size="icon-sm"
                          aria-label="Encerrar viagem"
                          title="Encerrar viagem"
                          onClick={() => setDialog({ mode: "finish", trip: t })}
                        >
                          <Flag />
                        </Button>
                      )}
                      <RowActions
                        label="viagem"
                        onEdit={() => setDialog({ mode: "edit", trip: t })}
                        onDelete={() => setDeleting(t)}
                      />
                    </div>
                  </TableCell>
                </TableRow>
              );
            })}
          </TableBody>
        </Table>
      </ListSection>
      <TripDialog
        vehicleId={vehicleId}
        open={dialog !== null}
        onOpenChange={(o) => !o && setDialog(null)}
        mode={dialog?.mode ?? "start"}
        trip={dialog?.trip}
        currentOdometer={vehicle.data?.current_odometer}
      />
      <ConfirmDelete
        open={deleting !== null}
        onOpenChange={(o) => !o && setDeleting(null)}
        title="Excluir viagem?"
        description="O registro da viagem será removido. A quilometragem do veículo não muda."
        onConfirm={async () => {
          if (deleting) await remove.mutateAsync(deleting.id);
        }}
      />
    </>
  );
}
