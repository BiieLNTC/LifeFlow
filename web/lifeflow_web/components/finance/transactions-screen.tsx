"use client";

import { useMemo, useState } from "react";
import { ChevronLeft, ChevronRight, Plus } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import {
  ConfirmDelete,
  EmptyState,
  ErrorState,
  LoadingRows,
  OptionSelect,
  PageHeader,
  Segmented,
} from "@/components/finance/shared";
import { TransactionDialog } from "@/components/finance/transaction-dialog";
import { TransactionsTable } from "@/components/finance/transactions-table";
import {
  useCategories,
  useDeleteTransaction,
  usePeople,
  useTransactions,
} from "@/lib/finance/hooks";
import {
  formatCurrency,
  monthLabel,
  shiftMonth,
  toIsoDate,
  todayIso,
} from "@/lib/finance/format";
import { categoryOptions } from "@/lib/finance/options";
import type { Transaction } from "@/lib/finance/api";

type TypeFilter = "all" | "expense" | "income";

export function TransactionsScreen() {
  const now = todayIso();
  const [period, setPeriod] = useState({
    year: Number(now.slice(0, 4)),
    month: Number(now.slice(5, 7)),
  });
  const [search, setSearch] = useState("");
  const [type, setType] = useState<TypeFilter>("all");
  const [categoryId, setCategoryId] = useState("");
  const [editing, setEditing] = useState<Transaction | null>(null);
  const [creating, setCreating] = useState(false);
  const [deleting, setDeleting] = useState<Transaction | null>(null);

  const range = useMemo(() => {
    const last = new Date(period.year, period.month, 0).getDate();
    return {
      from: toIsoDate(period.year, period.month, 1),
      to: toIsoDate(period.year, period.month, last),
    };
  }, [period]);

  const transactions = useTransactions(range);
  const categories = useCategories();
  const people = usePeople();
  const remove = useDeleteTransaction();

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    return (transactions.data ?? []).filter(
      (t) =>
        (type === "all" || t.type === type) &&
        (!categoryId || t.category_id === categoryId) &&
        (!q || t.description.toLowerCase().includes(q)),
    );
  }, [transactions.data, search, type, categoryId]);

  const totals = useMemo(() => {
    let income = 0;
    let expense = 0;
    for (const t of filtered) {
      if (t.type === "income") income += t.amount;
      else expense += t.amount;
    }
    return { income, expense };
  }, [filtered]);

  const loading = transactions.isPending || categories.isPending || people.isPending;
  const failed = transactions.isError || categories.isError || people.isError;

  return (
    <div className="flex flex-col gap-6">
      <PageHeader
        title="Transações"
        actions={
          <Button onClick={() => setCreating(true)}>
            <Plus /> Nova transação
          </Button>
        }
      />

      <div className="flex flex-wrap items-center gap-3">
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
        <Input
          className="max-w-56"
          placeholder="Buscar descrição"
          aria-label="Buscar descrição"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
        <div className="w-56">
          <Segmented<TypeFilter>
            value={type}
            onChange={setType}
            options={[
              { value: "all", label: "Todas" },
              { value: "expense", label: "Despesas" },
              { value: "income", label: "Receitas" },
            ]}
          />
        </div>
        <div className="w-48">
          <OptionSelect
            value={categoryId}
            onChange={setCategoryId}
            options={categoryOptions(categories.data ?? [], "any")}
            emptyLabel="Todas as categorias"
          />
        </div>
      </div>

      <Card className="p-2 sm:p-4">
        {loading ? (
          <LoadingRows rows={6} />
        ) : failed ? (
          <ErrorState
            message="Não foi possível carregar as transações."
            onRetry={() => {
              void transactions.refetch();
              void categories.refetch();
              void people.refetch();
            }}
          />
        ) : filtered.length === 0 ? (
          <EmptyState
            title={
              transactions.data?.length
                ? "Nenhuma transação com esses filtros."
                : "Nenhuma transação neste mês."
            }
            description="Registre receitas, despesas, compras parceladas ou recorrentes."
            action={
              <Button onClick={() => setCreating(true)}>
                <Plus /> Nova transação
              </Button>
            }
          />
        ) : (
          <>
            <TransactionsTable
              transactions={filtered}
              categories={categories.data ?? []}
              people={people.data ?? []}
              onEdit={setEditing}
              onDelete={setDeleting}
            />
            <div className="flex justify-end gap-6 border-t px-2 pt-3 text-sm">
              <span className="text-muted-foreground">
                Receitas{" "}
                <strong className="font-medium text-primary">{formatCurrency(totals.income)}</strong>
              </span>
              <span className="text-muted-foreground">
                Despesas{" "}
                <strong className="font-medium text-foreground">{formatCurrency(totals.expense)}</strong>
              </span>
            </div>
          </>
        )}
      </Card>

      <TransactionDialog open={creating} onOpenChange={setCreating} />
      <TransactionDialog
        open={editing !== null}
        onOpenChange={(open) => !open && setEditing(null)}
        initial={editing}
      />
      <ConfirmDelete
        open={deleting !== null}
        onOpenChange={(open) => !open && setDeleting(null)}
        title="Excluir transação?"
        description={
          deleting?.installment_total
            ? `“${deleting.description}” (parcela ${deleting.installment_index}/${deleting.installment_total}). As demais parcelas não serão afetadas.`
            : `“${deleting?.description ?? ""}” será removida do seu histórico.`
        }
        onConfirm={async () => {
          if (deleting) await remove.mutateAsync(deleting.id);
        }}
      />
    </div>
  );
}
