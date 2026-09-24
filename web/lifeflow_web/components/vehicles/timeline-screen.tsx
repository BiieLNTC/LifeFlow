"use client";

import { Fuel, Receipt, Wrench, type LucideIcon } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import {
  EmptyState,
  ErrorState,
  LoadingRows,
  PageHeader,
  SectionTitle,
} from "@/components/finance/shared";
import { formatCurrency, formatDate, monthLabel } from "@/lib/finance/format";
import { formatOdometer } from "@/lib/vehicles/format";
import { useTimeline } from "@/lib/vehicles/hooks";
import { timelineCategoryLabel, timelineTypeLabels } from "@/lib/vehicles/options";
import type { TimelineEntry } from "@/lib/vehicles/api";

const icons: Record<TimelineEntry["event_type"], LucideIcon> = {
  maintenance: Wrench,
  refueling: Fuel,
  expense: Receipt,
};

/** Agrupa (já ordenado, mais recente primeiro) por mês de `occurred_on`. */
function groupByMonth(entries: TimelineEntry[]) {
  const groups: { key: string; label: string; entries: TimelineEntry[] }[] = [];
  for (const entry of entries) {
    const [y, m] = entry.occurred_on.split("-").map(Number);
    const key = `${y}-${m}`;
    const last = groups[groups.length - 1];
    if (last?.key === key) last.entries.push(entry);
    else groups.push({ key, label: monthLabel(y, m), entries: [entry] });
  }
  return groups;
}

export function TimelineScreen({ vehicleId }: { vehicleId: string }) {
  const timeline = useTimeline(vehicleId);
  const entries = timeline.data?.pages.flat() ?? [];

  return (
    <div className="flex flex-col gap-6">
      <PageHeader
        title="Histórico"
        description="Toda a vida do veículo: manutenções, abastecimentos e despesas."
      />
      {timeline.isPending ? (
        <LoadingRows rows={5} />
      ) : timeline.isError ? (
        <ErrorState
          message="Não foi possível carregar o histórico."
          onRetry={() => void timeline.refetch()}
        />
      ) : entries.length === 0 ? (
        <Card>
          <EmptyState
            title="O histórico está vazio."
            description="Manutenções, abastecimentos e despesas registrados aparecem aqui."
          />
        </Card>
      ) : (
        <>
          {groupByMonth(entries).map((group) => (
            <section key={group.key} className="flex flex-col gap-2">
              <SectionTitle>{group.label}</SectionTitle>
              <Card className="gap-0 divide-y p-0">
                {group.entries.map((e) => {
                  const Icon = icons[e.event_type];
                  const category = timelineCategoryLabel(e.event_type, e.category);
                  return (
                    <div key={`${e.event_type}:${e.event_id}`} className="flex items-center gap-3 p-4">
                      <div className="flex size-9 shrink-0 items-center justify-center rounded-xl bg-muted text-muted-foreground">
                        <Icon className="size-4" />
                      </div>
                      <div className="min-w-0 flex-1">
                        <p className="truncate font-medium">{e.title}</p>
                        <p className="truncate text-xs text-muted-foreground">
                          {timelineTypeLabels[e.event_type]}
                          {category && ` · ${category}`}
                          {e.secondary_text && ` · ${e.secondary_text}`}
                        </p>
                      </div>
                      <div className="shrink-0 text-right">
                        <p className="font-medium tabular-nums">{formatCurrency(e.amount)}</p>
                        <p className="text-xs text-muted-foreground tabular-nums">
                          {formatDate(e.occurred_on)}
                          {e.odometer !== null && ` · ${formatOdometer(e.odometer)}`}
                        </p>
                      </div>
                    </div>
                  );
                })}
              </Card>
            </section>
          ))}
          {timeline.hasNextPage && (
            <div className="flex justify-center">
              <Button
                variant="outline"
                onClick={() => void timeline.fetchNextPage()}
                disabled={timeline.isFetchingNextPage}
              >
                {timeline.isFetchingNextPage ? "Carregando…" : "Carregar mais"}
              </Button>
            </div>
          )}
        </>
      )}
    </div>
  );
}
