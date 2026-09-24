"use client";

import { useState } from "react";
import { ChevronLeft, ChevronRight, Pencil, Plus, Trash2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { BudgetDialog } from "@/components/finance/budget-dialog";
import {
  ConfirmDelete,
  EmptyState,
  ErrorState,
  LoadingRows,
  PageHeader,
} from "@/components/finance/shared";
import { BudgetRow } from "@/components/finance/budget-row";
import { useBudgetProgress, useDeleteBudget } from "@/lib/finance/hooks";
import { monthLabel, shiftMonth, todayIso } from "@/lib/finance/format";
import type { BudgetProgress } from "@/lib/finance/api";

export function BudgetsScreen() {
  const now = todayIso();
  const [period, setPeriod] = useState({
    year: Number(now.slice(0, 4)),
    month: Number(now.slice(5, 7)),
  });
  const [creating, setCreating] = useState(false);
  const [editing, setEditing] = useState<BudgetProgress | null>(null);
  const [deleting, setDeleting] = useState<BudgetProgress | null>(null);

  const budgets = useBudgetProgress(period.year, period.month);
  const remove = useDeleteBudget();

  return (
    <div className="flex flex-col gap-6">
      <PageHeader
        title="Orçamentos"
        description="Limite mensal de gastos por categoria."
        actions={
          <Button onClick={() => setCreating(true)}>
            <Plus /> Novo orçamento
          </Button>
        }
      />

      <div className="flex items-center gap-1">
        <Button
          variant="outline"
          size="icon"
          aria-label="Mês anterior"
          onClick={() => setPeriod((p) => shiftMonth(p.year, p.month, -1))}
        >
          <ChevronLeft />
        </Button>
        <span className="w-44 text-center text-sm font-medium">
          {monthLabel(period.year, period.month)}
        </span>
        <Button
          variant="outline"
          size="icon"
          aria-label="Próximo mês"
          onClick={() => setPeriod((p) => shiftMonth(p.year, p.month, 1))}
        >
          <ChevronRight />
        </Button>
      </div>

      <Card className="p-4">
        {budgets.isPending ? (
          <LoadingRows />
        ) : budgets.isError ? (
          <ErrorState
            message="Não foi possível carregar os orçamentos."
            onRetry={() => void budgets.refetch()}
          />
        ) : budgets.data.length === 0 ? (
          <EmptyState
            title="Nenhum orçamento neste mês."
            description="Defina um limite por categoria para acompanhar quanto já gastou."
            action={
              <Button onClick={() => setCreating(true)}>
                <Plus /> Novo orçamento
              </Button>
            }
          />
        ) : (
          <ul className="flex flex-col gap-5">
            {budgets.data.map((b) => (
              <li key={b.budget_id} className="flex items-start gap-2">
                <div className="min-w-0 flex-1">
                  <BudgetRow budget={b} />
                </div>
                <Button
                  variant="ghost"
                  size="icon-sm"
                  aria-label={`Editar orçamento de ${b.category_description}`}
                  onClick={() => setEditing(b)}
                >
                  <Pencil />
                </Button>
                <Button
                  variant="ghost"
                  size="icon-sm"
                  aria-label={`Excluir orçamento de ${b.category_description}`}
                  onClick={() => setDeleting(b)}
                >
                  <Trash2 />
                </Button>
              </li>
            ))}
          </ul>
        )}
      </Card>

      <BudgetDialog open={creating} onOpenChange={setCreating} period={period} />
      <BudgetDialog
        open={editing !== null}
        onOpenChange={(open) => !open && setEditing(null)}
        period={period}
        initial={editing}
      />
      <ConfirmDelete
        open={deleting !== null}
        onOpenChange={(open) => !open && setDeleting(null)}
        title="Excluir orçamento?"
        description={`O limite de “${deleting?.category_description ?? ""}” em ${monthLabel(period.year, period.month)} será removido. As transações não são afetadas.`}
        onConfirm={async () => {
          if (deleting?.budget_id) await remove.mutateAsync(deleting.budget_id);
        }}
      />
    </div>
  );
}
