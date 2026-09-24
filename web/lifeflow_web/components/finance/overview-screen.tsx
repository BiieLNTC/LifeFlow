"use client";

import Link from "next/link";
import { useEffect, useRef, useState } from "react";
import { ArrowDown, ArrowUp, Plus } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { BudgetRow } from "@/components/finance/budget-row";
import { GoalSummary } from "@/components/finance/goals-screen";
import {
  EmptyState,
  ErrorState,
  LoadingRows,
  PageHeader,
  SectionTitle,
} from "@/components/finance/shared";
import { TransactionDialog } from "@/components/finance/transaction-dialog";
import { TransactionsTable } from "@/components/finance/transactions-table";
import {
  useBudgetProgress,
  useCategories,
  useGenerateRecurring,
  useGoals,
  usePeople,
  useRecentTransactions,
  useTotals,
} from "@/lib/finance/hooks";
import { formatCurrency, monthLabel, todayIso } from "@/lib/finance/format";

export function OverviewScreen() {
  const now = todayIso();
  const year = Number(now.slice(0, 4));
  const month = Number(now.slice(5, 7));

  const totals = useTotals();
  const budgets = useBudgetProgress(year, month);
  const goals = useGoals();
  const recent = useRecentTransactions(10);
  const categories = useCategories();
  const people = usePeople();
  const [creating, setCreating] = useState(false);

  // Gera ocorrências de recorrência pendentes ao abrir a tela (nunca por cron — ROADMAP §1.5).
  const generate = useGenerateRecurring();
  const generated = useRef(false);
  useEffect(() => {
    if (generated.current) return;
    generated.current = true;
    generate.mutate();
    // eslint-disable-next-line react-hooks/exhaustive-deps -- dispara uma única vez por montagem
  }, []);

  const featured = goals.data?.[0];

  return (
    <div className="flex flex-col gap-8">
      <PageHeader
        title="Finanças"
        actions={
          <Button onClick={() => setCreating(true)}>
            <Plus /> Nova transação
          </Button>
        }
      />

      <Card className="p-6">
        {totals.isPending ? (
          <LoadingRows rows={2} />
        ) : totals.isError ? (
          <ErrorState message="Não foi possível carregar o saldo." onRetry={() => void totals.refetch()} />
        ) : (
          <div className="flex flex-col gap-5">
            <div>
              <SectionTitle>Saldo</SectionTitle>
              <p className="mt-2 font-heading text-4xl font-bold tabular-nums">
                {formatCurrency(totals.data.balance ?? 0)}
              </p>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <Metric
                icon={<ArrowUp className="size-4 text-primary" />}
                label="receitas do mês"
                value={totals.data.monthly_income ?? 0}
              />
              <Metric
                icon={<ArrowDown className="size-4 text-critical" />}
                label="despesas do mês"
                value={totals.data.monthly_expense ?? 0}
              />
            </div>
          </div>
        )}
      </Card>

      <div className="grid gap-8 lg:grid-cols-2">
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

        <section className="flex flex-col gap-3">
          <div className="flex items-center justify-between">
            <SectionTitle>Meta</SectionTitle>
            <Link href="/finance/goals" className="text-xs text-primary hover:underline">
              Ver todas
            </Link>
          </div>
          <Card className="p-4">
            {goals.isPending ? (
              <LoadingRows rows={1} />
            ) : goals.isError ? (
              <ErrorState message="Não foi possível carregar as metas." onRetry={() => void goals.refetch()} />
            ) : featured ? (
              <Link href={`/finance/goals/${featured.id}`}>
                <GoalSummary goal={featured} />
              </Link>
            ) : (
              <p className="py-4 text-center text-sm text-muted-foreground">
                Nenhuma meta de poupança ainda.
              </p>
            )}
          </Card>
        </section>
      </div>

      <section className="flex flex-col gap-3">
        <div className="flex items-center justify-between">
          <SectionTitle>Transações recentes</SectionTitle>
          <Link href="/finance/transactions" className="text-xs text-primary hover:underline">
            Ver todas
          </Link>
        </div>
        <Card className="p-2 sm:p-4">
          {recent.isPending || categories.isPending || people.isPending ? (
            <LoadingRows rows={5} />
          ) : recent.isError || categories.isError || people.isError ? (
            <ErrorState
              message="Não foi possível carregar as transações."
              onRetry={() => {
                void recent.refetch();
                void categories.refetch();
                void people.refetch();
              }}
            />
          ) : recent.data.length === 0 ? (
            <EmptyState
              title="Nenhuma transação ainda."
              description="Registre sua primeira receita ou despesa."
              action={
                <Button onClick={() => setCreating(true)}>
                  <Plus /> Nova transação
                </Button>
              }
            />
          ) : (
            <TransactionsTable
              transactions={recent.data}
              categories={categories.data ?? []}
              people={people.data ?? []}
            />
          )}
        </Card>
      </section>

      <TransactionDialog open={creating} onOpenChange={setCreating} />
    </div>
  );
}

function Metric({
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
