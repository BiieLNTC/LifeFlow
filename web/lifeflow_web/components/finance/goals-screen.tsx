"use client";

import Link from "next/link";
import { useState } from "react";
import { PiggyBank, Plus } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { GoalDialog } from "@/components/finance/goal-dialogs";
import {
  EmptyState,
  ErrorState,
  LoadingRows,
  PageHeader,
  ProgressBar,
} from "@/components/finance/shared";
import { useGoals } from "@/lib/finance/hooks";
import { formatCurrency, formatDate } from "@/lib/finance/format";
import { goalSaved, type SavingsGoal } from "@/lib/finance/api";

export function goalPercent(goal: SavingsGoal): number {
  return goal.target_amount > 0 ? (goalSaved(goal) / goal.target_amount) * 100 : 0;
}

export function GoalSummary({ goal }: { goal: SavingsGoal }) {
  const saved = goalSaved(goal);
  const percent = goalPercent(goal);
  return (
    <div className="flex flex-col gap-2">
      <div className="flex items-baseline justify-between gap-3">
        <span className="truncate font-medium">{goal.title}</span>
        <span className="shrink-0 text-xs font-medium text-muted-foreground tabular-nums">
          {Math.round(percent)}%
        </span>
      </div>
      <ProgressBar percent={percent} />
      <p className="text-xs text-muted-foreground tabular-nums">
        {formatCurrency(saved)} de {formatCurrency(goal.target_amount)}
        {goal.target_date && ` · até ${formatDate(goal.target_date)}`}
      </p>
    </div>
  );
}

export function GoalsScreen() {
  const goals = useGoals();
  const [creating, setCreating] = useState(false);

  return (
    <div className="flex flex-col gap-6">
      <PageHeader
        title="Metas de poupança"
        actions={
          <Button onClick={() => setCreating(true)}>
            <Plus /> Nova meta
          </Button>
        }
      />
      {goals.isPending ? (
        <LoadingRows rows={3} />
      ) : goals.isError ? (
        <ErrorState
          message="Não foi possível carregar as metas."
          onRetry={() => void goals.refetch()}
        />
      ) : goals.data.length === 0 ? (
        <Card>
          <EmptyState
            title="Nenhuma meta ainda."
            description="Crie uma meta e registre aportes para acompanhar o progresso."
            action={
              <Button onClick={() => setCreating(true)}>
                <Plus /> Nova meta
              </Button>
            }
          />
        </Card>
      ) : (
        <div className="grid gap-4 md:grid-cols-2">
          {goals.data.map((goal) => (
            <Link key={goal.id} href={`/finance/goals/${goal.id}`}>
              <Card className="flex-row items-start gap-3 p-4 transition-colors hover:bg-accent">
                <PiggyBank className="mt-0.5 size-5 shrink-0 text-primary" />
                <div className="min-w-0 flex-1">
                  <GoalSummary goal={goal} />
                </div>
              </Card>
            </Link>
          ))}
        </div>
      )}
      <GoalDialog open={creating} onOpenChange={setCreating} />
    </div>
  );
}
