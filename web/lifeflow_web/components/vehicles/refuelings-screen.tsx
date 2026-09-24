"use client";

import { useState } from "react";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { ConfirmDelete } from "@/components/finance/shared";
import { RefuelingDialog } from "@/components/vehicles/refueling-dialog";
import { ListSection, RowActions } from "@/components/vehicles/shared";
import { formatCurrency, formatDate } from "@/lib/finance/format";
import { formatConsumption, formatLiters, formatOdometer } from "@/lib/vehicles/format";
import { useDeleteRefueling, useRefuelings, useVehicle } from "@/lib/vehicles/hooks";
import { fuelTypeLabels } from "@/lib/vehicles/options";
import type { Refueling } from "@/lib/vehicles/api";

export function RefuelingsScreen({ vehicleId }: { vehicleId: string }) {
  const refuelings = useRefuelings(vehicleId);
  const vehicle = useVehicle(vehicleId);
  const remove = useDeleteRefueling();
  const [creating, setCreating] = useState(false);
  const [editing, setEditing] = useState<Refueling | null>(null);
  const [deleting, setDeleting] = useState<Refueling | null>(null);
  const data = refuelings.data ?? [];

  return (
    <>
      <ListSection
        title="Abastecimentos"
        description="Combustível e consumo médio entre tanques cheios."
        actionLabel="Novo abastecimento"
        onAction={() => setCreating(true)}
        query={refuelings}
        isEmpty={data.length === 0}
        emptyTitle="Nenhum abastecimento registrado."
        emptyDescription="Registre abastecimentos com tanque cheio para calcular o consumo."
        errorMessage="Não foi possível carregar os abastecimentos."
      >
        <Table>
          <TableHeader>
            <TableRow className="hover:bg-transparent">
              <TableHead className="w-28">Data</TableHead>
              <TableHead>Combustível</TableHead>
              <TableHead className="hidden md:table-cell">Quilometragem</TableHead>
              <TableHead className="hidden text-right lg:table-cell">Litros</TableHead>
              <TableHead className="hidden text-right lg:table-cell">Consumo</TableHead>
              <TableHead className="text-right">Total</TableHead>
              <TableHead className="w-24" />
            </TableRow>
          </TableHeader>
          <TableBody>
            {data.map((r) => (
              <TableRow key={r.id}>
                <TableCell className="text-muted-foreground">{formatDate(r.refueling_date)}</TableCell>
                <TableCell className="whitespace-normal">
                  <span className="font-medium">
                    {fuelTypeLabels[r.fuel_type as keyof typeof fuelTypeLabels] ?? r.fuel_type}
                  </span>
                  {r.gas_station && (
                    <span className="block text-xs text-muted-foreground">{r.gas_station}</span>
                  )}
                </TableCell>
                <TableCell className="hidden tabular-nums md:table-cell">
                  {formatOdometer(r.odometer)}
                </TableCell>
                <TableCell className="hidden text-right tabular-nums lg:table-cell">
                  {formatLiters(r.liters)}
                </TableCell>
                <TableCell className="hidden text-right tabular-nums lg:table-cell">
                  {r.consumption_km_l != null ? formatConsumption(r.consumption_km_l) : "—"}
                </TableCell>
                <TableCell className="text-right font-medium tabular-nums">
                  {formatCurrency(r.total_amount)}
                </TableCell>
                <TableCell>
                  <RowActions
                    label={`abastecimento de ${formatDate(r.refueling_date)}`}
                    onEdit={() => setEditing(r)}
                    onDelete={() => setDeleting(r)}
                  />
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </ListSection>
      <RefuelingDialog
        vehicleId={vehicleId}
        open={creating}
        onOpenChange={setCreating}
        defaultOdometer={vehicle.data?.current_odometer}
        defaultFuelType={vehicle.data?.fuel_type}
      />
      <RefuelingDialog
        vehicleId={vehicleId}
        open={editing !== null}
        onOpenChange={(o) => !o && setEditing(null)}
        initial={editing}
      />
      <ConfirmDelete
        open={deleting !== null}
        onOpenChange={(o) => !o && setDeleting(null)}
        title="Excluir abastecimento?"
        description="O registro será removido, junto com a transação gerada em Finanças."
        onConfirm={async () => {
          if (deleting) await remove.mutateAsync(deleting.id);
        }}
      />
    </>
  );
}
