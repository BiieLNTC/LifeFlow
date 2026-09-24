"use client";

import Link from "next/link";
import { useState } from "react";
import { Fuel, Receipt, Wrench } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { ErrorState, LoadingRows, SectionTitle } from "@/components/finance/shared";
import { ExpenseDialog } from "@/components/vehicles/expense-dialog";
import { MaintenanceDialog } from "@/components/vehicles/maintenance-dialog";
import { RefuelingDialog } from "@/components/vehicles/refueling-dialog";
import { reminderRemaining } from "@/components/vehicles/reminders-screen";
import {
  StatTile,
  UrgencyBadge,
  documentUrgency,
} from "@/components/vehicles/shared";
import { formatCurrency, formatDate, todayIso } from "@/lib/finance/format";
import {
  daysUntil,
  formatConsumption,
  formatOdometer,
} from "@/lib/vehicles/format";
import { useDashboard, useDocuments, useVehicle } from "@/lib/vehicles/hooks";
import { documentTypeLabels } from "@/lib/vehicles/options";

type Quick = "maintenance" | "refueling" | "expense" | null;

export function OverviewScreen({ vehicleId }: { vehicleId: string }) {
  const dashboard = useDashboard(vehicleId);
  const documents = useDocuments(vehicleId);
  const vehicle = useVehicle(vehicleId);
  const [quick, setQuick] = useState<Quick>(null);

  if (dashboard.isPending) return <LoadingRows rows={4} />;
  if (dashboard.isError) {
    return (
      <ErrorState
        message="Não foi possível carregar o resumo do veículo."
        onRetry={() => void dashboard.refetch()}
      />
    );
  }

  const d = dashboard.data;
  const today = todayIso();
  const expiring = (documents.data ?? [])
    .filter((doc) => doc.expiry_date && daysUntil(doc.expiry_date, today) <= 30)
    .sort((a, b) => (a.expiry_date as string).localeCompare(b.expiry_date as string));

  const nextReminder =
    d.next_reminder_id && d.next_reminder_description
      ? {
          description: d.next_reminder_description,
          status: (d.next_reminder_status ?? "upcoming") as "overdue" | "near" | "upcoming",
          remaining_km: d.next_reminder_remaining_km,
          remaining_days: d.next_reminder_remaining_days,
        }
      : null;

  return (
    <div className="flex flex-col gap-8">
      <div className="flex flex-wrap gap-2">
        <Button onClick={() => setQuick("refueling")}>
          <Fuel /> Abastecer
        </Button>
        <Button variant="outline" onClick={() => setQuick("maintenance")}>
          <Wrench /> Manutenção
        </Button>
        <Button variant="outline" onClick={() => setQuick("expense")}>
          <Receipt /> Despesa
        </Button>
      </div>

      <section className="flex flex-col gap-3">
        <SectionTitle>Este mês</SectionTitle>
        <Card className="grid grid-cols-2 gap-6 p-5 lg:grid-cols-4">
          <StatTile label="Gasto no mês" value={formatCurrency(d.monthly_spending)} />
          <StatTile
            label="Consumo"
            value={d.consumption_km_l != null ? formatConsumption(d.consumption_km_l) : "—"}
            hint={d.consumption_km_l == null ? "Precisa de 2 tanques cheios" : undefined}
          />
          <StatTile
            label="Custo por km"
            value={d.cost_per_km != null ? formatCurrency(d.cost_per_km) : "—"}
          />
          <StatTile
            label="Rodado"
            value={d.monthly_distance_km != null ? formatOdometer(d.monthly_distance_km) : "—"}
            hint={d.monthly_distance_km == null ? "Precisa de 2 abastecimentos" : undefined}
          />
        </Card>
      </section>

      <div className="grid gap-8 md:grid-cols-2">
        <section className="flex flex-col gap-3">
          <SectionTitle>Próximo cuidado</SectionTitle>
          <Card className="gap-1 p-5">
            {nextReminder ? (
              <>
                <div className="flex items-start justify-between gap-3">
                  <span className="font-medium">{nextReminder.description}</span>
                  <UrgencyBadge status={nextReminder.status} />
                </div>
                <span className="text-sm text-muted-foreground">
                  {reminderRemaining(nextReminder)}
                </span>
              </>
            ) : (
              <span className="text-sm text-muted-foreground">Nenhum lembrete ativo.</span>
            )}
            <Link
              href={`/vehicles/${vehicleId}/reminders`}
              className="mt-2 text-sm font-medium text-primary hover:underline"
            >
              {d.attention_count > 0
                ? `${d.attention_count} ${d.attention_count === 1 ? "lembrete pede" : "lembretes pedem"} atenção`
                : "Ver lembretes"}
            </Link>
          </Card>
        </section>

        <section className="flex flex-col gap-3">
          <SectionTitle>Documentos</SectionTitle>
          <Card className="gap-3 p-5">
            {documents.isPending ? (
              <LoadingRows rows={1} />
            ) : expiring.length === 0 ? (
              <span className="text-sm text-muted-foreground">Nenhum vencimento nos próximos 30 dias.</span>
            ) : (
              expiring.map((doc) => (
                <div key={doc.id} className="flex items-start justify-between gap-3">
                  <div className="min-w-0">
                    <p className="truncate font-medium">{doc.description}</p>
                    <p className="text-xs text-muted-foreground">
                      {documentTypeLabels[doc.type as keyof typeof documentTypeLabels] ?? doc.type} · vence em{" "}
                      {formatDate(doc.expiry_date as string)}
                    </p>
                  </div>
                  <UrgencyBadge
                    status={documentUrgency(daysUntil(doc.expiry_date as string, today))}
                  />
                </div>
              ))
            )}
            <Link
              href={`/vehicles/${vehicleId}/documents`}
              className="text-sm font-medium text-primary hover:underline"
            >
              Ver documentos
            </Link>
          </Card>
        </section>
      </div>

      <MaintenanceDialog
        vehicleId={vehicleId}
        open={quick === "maintenance"}
        onOpenChange={(o) => !o && setQuick(null)}
        defaultOdometer={vehicle.data?.current_odometer}
      />
      <RefuelingDialog
        vehicleId={vehicleId}
        open={quick === "refueling"}
        onOpenChange={(o) => !o && setQuick(null)}
        defaultOdometer={vehicle.data?.current_odometer}
        defaultFuelType={vehicle.data?.fuel_type}
      />
      <ExpenseDialog
        vehicleId={vehicleId}
        open={quick === "expense"}
        onOpenChange={(o) => !o && setQuick(null)}
      />
    </div>
  );
}
