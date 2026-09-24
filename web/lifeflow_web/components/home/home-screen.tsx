"use client";

import Link from "next/link";
import { useState } from "react";
import { ArrowDown, ArrowUp, Bike, Car, ChevronRight } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { BudgetRow } from "@/components/finance/budget-row";
import {
  ErrorState,
  LoadingRows,
  SectionTitle,
} from "@/components/finance/shared";
import { reminderRemaining } from "@/components/vehicles/reminders-screen";
import { UrgencyBadge } from "@/components/vehicles/shared";
import { formatCurrency, monthLabel, todayIso } from "@/lib/finance/format";
import { useBudgetProgress, useTotals } from "@/lib/finance/hooks";
import { formatOdometer } from "@/lib/vehicles/format";
import { useDashboards } from "@/lib/vehicles/hooks";
import { cn } from "@/lib/utils";

/** Home combinada (AGENTS.md §12): resumo de cada módulo, sem duplicar os dashboards completos. */
export function HomeScreen({ greeting }: { greeting: string }) {
  return (
    <div className="mx-auto flex max-w-5xl flex-col gap-8">
      <h1 className="font-heading text-2xl font-bold">Olá, {greeting}</h1>
      <BalanceCard />
      <div className="grid gap-8 lg:grid-cols-2">
        <VehicleSection />
        <BudgetsSection />
      </div>
    </div>
  );
}

function BalanceCard() {
  const totals = useTotals();
  return (
    <Card className="p-6">
      {totals.isPending ? (
        <LoadingRows rows={2} />
      ) : totals.isError ? (
        <ErrorState
          message="Não foi possível carregar o saldo."
          onRetry={() => void totals.refetch()}
        />
      ) : (
        <div className="flex flex-col gap-5">
          <div className="flex items-start justify-between gap-3">
            <div>
              <SectionTitle>Saldo</SectionTitle>
              <p className="mt-2 font-heading text-4xl font-bold tabular-nums">
                {formatCurrency(totals.data.balance ?? 0)}
              </p>
            </div>
            <Link
              href="/finance"
              className="flex items-center text-sm font-medium text-primary hover:underline"
            >
              Finanças <ChevronRight className="size-4" />
            </Link>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <Flow
              icon={<ArrowUp className="size-4 text-primary" />}
              label="receitas do mês"
              value={totals.data.monthly_income ?? 0}
            />
            <Flow
              icon={<ArrowDown className="size-4 text-critical" />}
              label="despesas do mês"
              value={totals.data.monthly_expense ?? 0}
            />
          </div>
        </div>
      )}
    </Card>
  );
}

function Flow({
  icon,
  label,
  value,
}: {
  icon: React.ReactNode;
  label: string;
  value: number;
}) {
  return (
    <div>
      <div className="flex items-center gap-1.5 font-semibold tabular-nums">
        {icon}
        {formatCurrency(value)}
      </div>
      <p className="mt-0.5 text-xs text-muted-foreground">{label}</p>
    </div>
  );
}

function VehicleSection() {
  const dashboards = useDashboards();
  const [selectedId, setSelectedId] = useState<string | null>(null);

  if (dashboards.isPending) {
    return (
      <section className="flex flex-col gap-3">
        <SectionTitle>Veículo</SectionTitle>
        <LoadingRows rows={2} />
      </section>
    );
  }
  if (dashboards.isError) {
    return (
      <section className="flex flex-col gap-3">
        <SectionTitle>Veículo</SectionTitle>
        <Card>
          <ErrorState
            message="Não foi possível carregar o veículo."
            onRetry={() => void dashboards.refetch()}
          />
        </Card>
      </section>
    );
  }

  const vehicles = dashboards.data;
  if (vehicles.length === 0) {
    return (
      <section className="flex flex-col gap-3">
        <SectionTitle>Veículo</SectionTitle>
        <Card className="items-center gap-3 p-6 text-center">
          <p className="text-sm text-muted-foreground">
            Cadastre um veículo para acompanhar custos e cuidados.
          </p>
          <Button render={<Link href="/vehicles" />}>Ir para Veículos</Button>
        </Card>
      </section>
    );
  }

  const selected = vehicles.find((v) => v.vehicle_id === selectedId) ?? vehicles[0];
  const Icon = selected.vehicle_type === "motorcycle" ? Bike : Car;
  const hasReminder = Boolean(selected.next_reminder_id && selected.next_reminder_description);
  const attention = selected.attention_count ?? 0;

  return (
    <section className="flex flex-col gap-3">
      <SectionTitle>Veículo</SectionTitle>
      {vehicles.length > 1 && (
        <div className="flex flex-wrap gap-2" role="radiogroup" aria-label="Veículo em destaque">
          {vehicles.map((v) => (
            <button
              key={v.vehicle_id}
              type="button"
              role="radio"
              aria-checked={v.vehicle_id === selected.vehicle_id}
              onClick={() => setSelectedId(v.vehicle_id)}
              className={cn(
                "rounded-full px-3.5 py-1.5 text-sm font-medium transition-colors",
                v.vehicle_id === selected.vehicle_id
                  ? "bg-primary/10 text-primary"
                  : "bg-muted text-muted-foreground hover:text-foreground",
              )}
            >
              {v.nickname}
            </button>
          ))}
        </div>
      )}
      <Link href={`/vehicles/${selected.vehicle_id}`}>
        <Card className="gap-3 p-5 transition-colors hover:bg-accent">
          <div className="flex items-start gap-3">
            <div className="flex size-10 shrink-0 items-center justify-center rounded-xl bg-muted text-muted-foreground">
              <Icon className="size-5" />
            </div>
            <div className="min-w-0 flex-1">
              <p className="truncate font-heading text-lg font-bold">{selected.nickname}</p>
              <p className="truncate text-sm text-muted-foreground">
                {selected.brand} {selected.model}
                {selected.model_year && ` · ${selected.model_year}`}
              </p>
            </div>
            {attention > 0 && (
              <Badge variant="ghost" className="bg-warning/10 text-warning">
                {attention} {attention === 1 ? "cuidado" : "cuidados"}
              </Badge>
            )}
          </div>
          <div className="flex items-baseline justify-between gap-3 text-sm">
            <span className="text-muted-foreground tabular-nums">
              {formatOdometer(selected.current_odometer ?? 0)}
            </span>
            <span className="font-medium tabular-nums">
              {formatCurrency(selected.monthly_spending ?? 0)}{" "}
              <span className="font-normal text-muted-foreground">no mês</span>
            </span>
          </div>
        </Card>
      </Link>

      <SectionTitle>Próximo cuidado</SectionTitle>
      <Link href={`/vehicles/${selected.vehicle_id}/reminders`}>
        <Card className="gap-1 p-5 transition-colors hover:bg-accent">
          {hasReminder ? (
            <>
              <div className="flex items-start justify-between gap-3">
                <span className="font-medium">{selected.next_reminder_description}</span>
                <UrgencyBadge
                  status={(selected.next_reminder_status ?? "upcoming") as "overdue" | "near" | "upcoming"}
                />
              </div>
              <span className="text-sm text-muted-foreground">
                {reminderRemaining({
                  remaining_km: selected.next_reminder_remaining_km,
                  remaining_days: selected.next_reminder_remaining_days,
                })}
              </span>
            </>
          ) : (
            <span className="text-sm text-muted-foreground">Nenhum lembrete ativo.</span>
          )}
        </Card>
      </Link>
    </section>
  );
}

function BudgetsSection() {
  const now = todayIso();
  const year = Number(now.slice(0, 4));
  const month = Number(now.slice(5, 7));
  const budgets = useBudgetProgress(year, month);

  return (
    <section className="flex flex-col gap-3">
      <div className="flex items-center justify-between">
        <SectionTitle>Orçamentos · {monthLabel(year, month)}</SectionTitle>
        <Link href="/finance/budgets" className="text-xs text-primary hover:underline">
          Gerenciar
        </Link>
      </div>
      <Card className="p-4">
        {budgets.isPending ? (
          <LoadingRows rows={2} />
        ) : budgets.isError ? (
          <ErrorState
            message="Não foi possível carregar os orçamentos."
            onRetry={() => void budgets.refetch()}
          />
        ) : budgets.data.length === 0 ? (
          <p className="py-4 text-center text-sm text-muted-foreground">
            Nenhum orçamento definido para este mês.
          </p>
        ) : (
          <ul className="flex flex-col gap-5">
            {budgets.data.map((b) => (
              <li key={b.budget_id}>
                <BudgetRow budget={b} />
              </li>
            ))}
          </ul>
        )}
      </Card>
    </section>
  );
}
