"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { Bike, Car, Plus } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import {
  EmptyState,
  ErrorState,
  LoadingRows,
  PageHeader,
} from "@/components/finance/shared";
import { VehicleDialog } from "@/components/vehicles/vehicle-dialog";
import { formatCurrency } from "@/lib/finance/format";
import { formatOdometer, formatPlate } from "@/lib/vehicles/format";
import { useDashboards, useVehicles } from "@/lib/vehicles/hooks";
import { vehicleTypeLabels } from "@/lib/vehicles/options";

export function VehiclesScreen() {
  const router = useRouter();
  const vehicles = useVehicles();
  const dashboards = useDashboards();
  const [creating, setCreating] = useState(false);

  const dashboardById = new Map((dashboards.data ?? []).map((d) => [d.vehicle_id, d]));
  const newButton = (
    <Button onClick={() => setCreating(true)}>
      <Plus /> Novo veículo
    </Button>
  );

  return (
    <div className="mx-auto flex max-w-5xl flex-col gap-6">
      <PageHeader
        title="Veículos"
        description="Prontuário digital: manutenções, abastecimentos, despesas e lembretes."
        actions={newButton}
      />
      {vehicles.isPending ? (
        <LoadingRows rows={3} />
      ) : vehicles.isError ? (
        <ErrorState
          message="Não foi possível carregar os veículos."
          onRetry={() => void vehicles.refetch()}
        />
      ) : vehicles.data.length === 0 ? (
        <Card>
          <EmptyState
            title="Nenhum veículo ainda."
            description="Cadastre seu primeiro veículo para acompanhar custos e cuidados."
            action={newButton}
          />
        </Card>
      ) : (
        <div className="grid gap-4 md:grid-cols-2">
          {vehicles.data.map((v) => {
            const dash = dashboardById.get(v.id);
            const Icon = v.vehicle_type === "motorcycle" ? Bike : Car;
            return (
              <Link key={v.id} href={`/vehicles/${v.id}`}>
                <Card className="gap-3 p-4 transition-colors hover:bg-accent">
                  <div className="flex items-start gap-3">
                    <div className="flex size-10 shrink-0 items-center justify-center rounded-xl bg-muted text-muted-foreground">
                      <Icon className="size-5" />
                    </div>
                    <div className="min-w-0 flex-1">
                      <p className="truncate font-heading text-lg font-bold">{v.nickname}</p>
                      <p className="truncate text-sm text-muted-foreground">
                        {v.brand} {v.model}
                        {v.model_year && ` · ${v.model_year}`}
                        {v.license_plate && ` · ${formatPlate(v.license_plate)}`}
                      </p>
                    </div>
                    {dash && dash.attention_count > 0 && (
                      <Badge variant="ghost" className="bg-warning/10 text-warning">
                        {dash.attention_count} {dash.attention_count === 1 ? "cuidado" : "cuidados"}
                      </Badge>
                    )}
                  </div>
                  <div className="flex items-baseline justify-between gap-3 text-sm">
                    <span className="text-muted-foreground tabular-nums">
                      {vehicleTypeLabels[v.vehicle_type as keyof typeof vehicleTypeLabels] ?? v.vehicle_type} ·{" "}
                      {formatOdometer(v.current_odometer)}
                    </span>
                    {dash && (
                      <span className="font-medium tabular-nums">
                        {formatCurrency(dash.monthly_spending)} <span className="font-normal text-muted-foreground">no mês</span>
                      </span>
                    )}
                  </div>
                </Card>
              </Link>
            );
          })}
        </div>
      )}
      <VehicleDialog
        open={creating}
        onOpenChange={setCreating}
        onSaved={(v) => router.push(`/vehicles/${v.id}`)}
      />
    </div>
  );
}
