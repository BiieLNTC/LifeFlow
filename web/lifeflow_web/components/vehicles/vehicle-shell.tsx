"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useState } from "react";
import { ArrowLeft, Pencil, Trash2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { ConfirmDelete, ErrorState, LoadingRows } from "@/components/finance/shared";
import { VehicleDialog } from "@/components/vehicles/vehicle-dialog";
import { formatOdometer, formatPlate } from "@/lib/vehicles/format";
import { useDeleteVehicle, useVehicle } from "@/lib/vehicles/hooks";
import { vehicleTypeLabels } from "@/lib/vehicles/options";
import { cn } from "@/lib/utils";

const tabs = [
  { path: "", label: "Visão geral" },
  { path: "/timeline", label: "Histórico" },
  { path: "/maintenances", label: "Manutenções" },
  { path: "/refuelings", label: "Abastecimentos" },
  { path: "/expenses", label: "Despesas" },
  { path: "/reminders", label: "Lembretes" },
  { path: "/documents", label: "Documentos" },
  { path: "/trips", label: "Viagens" },
];

const backLink = (
  <Link
    href="/vehicles"
    className="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground"
  >
    <ArrowLeft className="size-4" /> Veículos
  </Link>
);

export function VehicleShell({
  vehicleId,
  children,
}: {
  vehicleId: string;
  children: React.ReactNode;
}) {
  const router = useRouter();
  const pathname = usePathname();
  const vehicle = useVehicle(vehicleId);
  const remove = useDeleteVehicle();
  const [editing, setEditing] = useState(false);
  const [deleting, setDeleting] = useState(false);

  const base = `/vehicles/${vehicleId}`;

  // Durante/depois da remoção o veículo some da consulta; evita piscar "não encontrado".
  if (vehicle.isPending || remove.isPending || remove.isSuccess) {
    return (
      <div className="mx-auto flex max-w-5xl flex-col gap-6">
        {backLink}
        <LoadingRows rows={3} />
      </div>
    );
  }
  if (vehicle.isError) {
    return (
      <div className="mx-auto flex max-w-5xl flex-col gap-6">
        {backLink}
        <ErrorState
          message="Veículo não encontrado ou indisponível."
          onRetry={() => void vehicle.refetch()}
        />
      </div>
    );
  }

  const v = vehicle.data;
  return (
    <div className="mx-auto max-w-5xl">
      <div className="flex flex-col gap-3">
        {backLink}
        <div className="flex flex-wrap items-start justify-between gap-3">
          <div>
            <h1 className="font-heading text-2xl font-bold">{v.nickname}</h1>
            <p className="mt-1 text-muted-foreground">
              {v.brand} {v.model}
              {v.version && ` ${v.version}`}
              {v.model_year && ` · ${v.model_year}`}
              {v.license_plate && ` · ${formatPlate(v.license_plate)}`}
              {" · "}
              {vehicleTypeLabels[v.vehicle_type as keyof typeof vehicleTypeLabels] ?? v.vehicle_type}
              {" · "}
              <span className="tabular-nums">{formatOdometer(v.current_odometer)}</span>
            </p>
          </div>
          <div className="flex items-center gap-2">
            <Button variant="outline" onClick={() => setEditing(true)}>
              <Pencil /> Editar
            </Button>
            <Button variant="outline" onClick={() => setDeleting(true)}>
              <Trash2 /> Remover
            </Button>
          </div>
        </div>
      </div>

      <nav aria-label="Seções do veículo" className="mt-4 mb-6 flex gap-1 overflow-x-auto border-b">
        {tabs.map((tab) => {
          const href = base + tab.path;
          const active = tab.path === "" ? pathname === base : pathname.startsWith(href);
          return (
            <Link
              key={tab.path}
              href={href}
              aria-current={active ? "page" : undefined}
              className={cn(
                "-mb-px border-b-2 px-3 py-2 text-sm font-medium whitespace-nowrap transition-colors",
                active
                  ? "border-primary text-foreground"
                  : "border-transparent text-muted-foreground hover:text-foreground",
              )}
            >
              {tab.label}
            </Link>
          );
        })}
      </nav>

      {children}

      <VehicleDialog open={editing} onOpenChange={setEditing} initial={v} />
      <ConfirmDelete
        open={deleting}
        onOpenChange={setDeleting}
        title="Remover veículo?"
        description="O veículo deixa de aparecer no app. As transações geradas por ele em Finanças continuam no histórico."
        onConfirm={async () => {
          await remove.mutateAsync(v.id);
          router.replace("/vehicles");
        }}
      />
    </div>
  );
}
