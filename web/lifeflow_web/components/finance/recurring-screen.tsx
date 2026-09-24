"use client";

import { useState } from "react";
import { Pencil, Plus, RefreshCw, Trash2 } from "lucide-react";
import { toast } from "sonner";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { RecurringDialog } from "@/components/finance/recurring-dialog";
import { TransactionDialog } from "@/components/finance/transaction-dialog";
import {
  ConfirmDelete,
  EmptyState,
  ErrorState,
  LoadingRows,
  PageHeader,
} from "@/components/finance/shared";
import {
  useCategories,
  useDeleteRecurring,
  useGenerateRecurring,
  useRecurring,
} from "@/lib/finance/hooks";
import { formatCurrency } from "@/lib/finance/format";
import type { RecurringTransaction } from "@/lib/finance/api";

export function RecurringScreen() {
  const recurring = useRecurring();
  const categories = useCategories();
  const generate = useGenerateRecurring();
  const remove = useDeleteRecurring();
  const [creating, setCreating] = useState(false);
  const [editing, setEditing] = useState<RecurringTransaction | null>(null);
  const [deleting, setDeleting] = useState<RecurringTransaction | null>(null);

  const categoryName = new Map((categories.data ?? []).map((c) => [c.id, c.description]));

  async function generateNow() {
    try {
      const n = await generate.mutateAsync();
      toast(n === 0 ? "Nenhuma ocorrência pendente." : `${n} ocorrência(s) gerada(s).`);
    } catch (e) {
      toast.error(e instanceof Error ? e.message : "Não foi possível gerar as ocorrências.");
    }
  }

  return (
    <div className="mx-auto flex max-w-3xl flex-col gap-6">
      <PageHeader
        title="Transações recorrentes"
        description="Assinaturas, salário e outras transações mensais geradas automaticamente."
        actions={
          <>
            <Button variant="outline" onClick={generateNow} disabled={generate.isPending}>
              <RefreshCw className={generate.isPending ? "animate-spin" : undefined} /> Gerar pendentes
            </Button>
            <Button onClick={() => setCreating(true)}>
              <Plus /> Nova recorrência
            </Button>
          </>
        }
      />
      <Card className="p-2 sm:p-4">
        {recurring.isPending ? (
          <LoadingRows />
        ) : recurring.isError ? (
          <ErrorState
            message="Não foi possível carregar as recorrências."
            onRetry={() => void recurring.refetch()}
          />
        ) : recurring.data.length === 0 ? (
          <EmptyState
            title="Nenhuma recorrência cadastrada."
            description="Automatize o que se repete todo mês."
            action={
              <Button onClick={() => setCreating(true)}>
                <Plus /> Nova recorrência
              </Button>
            }
          />
        ) : (
          <Table>
            <TableHeader>
              <TableRow className="hover:bg-transparent">
                <TableHead>Descrição</TableHead>
                <TableHead className="hidden sm:table-cell">Categoria</TableHead>
                <TableHead>Dia</TableHead>
                <TableHead className="text-right">Valor</TableHead>
                <TableHead className="w-24" />
              </TableRow>
            </TableHeader>
            <TableBody>
              {recurring.data.map((r) => (
                <TableRow key={r.id}>
                  <TableCell>
                    <span className="flex flex-wrap items-center gap-2 font-medium">
                      {r.description}
                      {r.paused && <Badge variant="secondary">Pausada</Badge>}
                    </span>
                  </TableCell>
                  <TableCell className="hidden text-muted-foreground sm:table-cell">
                    {categoryName.get(r.category_id) ?? "Sem categoria"}
                  </TableCell>
                  <TableCell>{r.day_of_month}</TableCell>
                  <TableCell className="text-right font-medium tabular-nums">
                    {r.type === "income" ? "+" : "−"} {formatCurrency(r.amount)}
                  </TableCell>
                  <TableCell className="text-right">
                    <Button
                      variant="ghost"
                      size="icon-sm"
                      aria-label={`Editar ${r.description}`}
                      onClick={() => setEditing(r)}
                    >
                      <Pencil />
                    </Button>
                    <Button
                      variant="ghost"
                      size="icon-sm"
                      aria-label={`Remover ${r.description}`}
                      onClick={() => setDeleting(r)}
                    >
                      <Trash2 />
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        )}
      </Card>

      {/* A criação usa o diálogo de transação já no modo "Recorrente". */}
      <TransactionDialog open={creating} onOpenChange={setCreating} defaultMode="recurring" />
      <RecurringDialog
        open={editing !== null}
        onOpenChange={(open) => !open && setEditing(null)}
        initial={editing}
      />
      <ConfirmDelete
        open={deleting !== null}
        onOpenChange={(open) => !open && setDeleting(null)}
        title="Remover recorrência?"
        description={`“${deleting?.description ?? ""}” não gera mais ocorrências. As já geradas continuam no histórico.`}
        onConfirm={async () => {
          if (deleting) await remove.mutateAsync(deleting.id);
        }}
      />
    </div>
  );
}
