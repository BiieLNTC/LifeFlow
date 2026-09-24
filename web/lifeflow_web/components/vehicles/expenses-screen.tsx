"use client";

import { useState } from "react";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { ConfirmDelete } from "@/components/finance/shared";
import { ExpenseDialog } from "@/components/vehicles/expense-dialog";
import { ListSection, RowActions } from "@/components/vehicles/shared";
import { formatCurrency, formatDate } from "@/lib/finance/format";
import { useDeleteExpense, useExpenses } from "@/lib/vehicles/hooks";
import { expenseCategoryLabels } from "@/lib/vehicles/options";
import type { Expense } from "@/lib/vehicles/api";

const categoryLabel = (category: string) =>
  expenseCategoryLabels[category as keyof typeof expenseCategoryLabels] ?? category;

export function ExpensesScreen({ vehicleId }: { vehicleId: string }) {
  const expenses = useExpenses(vehicleId);
  const remove = useDeleteExpense();
  const [creating, setCreating] = useState(false);
  const [editing, setEditing] = useState<Expense | null>(null);
  const [deleting, setDeleting] = useState<Expense | null>(null);
  const data = expenses.data ?? [];

  return (
    <>
      <ListSection
        title="Despesas"
        description="Seguro, impostos, multas e outros custos do veículo."
        actionLabel="Nova despesa"
        onAction={() => setCreating(true)}
        query={expenses}
        isEmpty={data.length === 0}
        emptyTitle="Nenhuma despesa registrada."
        emptyDescription="Registre seguro, IPVA, pedágios e outros custos para ver o custo total."
        errorMessage="Não foi possível carregar as despesas."
      >
        <Table>
          <TableHeader>
            <TableRow className="hover:bg-transparent">
              <TableHead className="w-28">Data</TableHead>
              <TableHead>Descrição</TableHead>
              <TableHead className="hidden md:table-cell">Categoria</TableHead>
              <TableHead className="text-right">Valor</TableHead>
              <TableHead className="w-24" />
            </TableRow>
          </TableHeader>
          <TableBody>
            {data.map((e) => (
              <TableRow key={e.id}>
                <TableCell className="text-muted-foreground">{formatDate(e.expense_date)}</TableCell>
                <TableCell className="max-w-64 whitespace-normal">
                  <span className="font-medium">{e.description}</span>
                  <span className="mt-0.5 block text-xs text-muted-foreground md:hidden">
                    {categoryLabel(e.category)}
                  </span>
                </TableCell>
                <TableCell className="hidden md:table-cell">{categoryLabel(e.category)}</TableCell>
                <TableCell className="text-right font-medium tabular-nums">
                  {formatCurrency(e.amount)}
                </TableCell>
                <TableCell>
                  <RowActions
                    label={e.description}
                    onEdit={() => setEditing(e)}
                    onDelete={() => setDeleting(e)}
                  />
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </ListSection>
      <ExpenseDialog vehicleId={vehicleId} open={creating} onOpenChange={setCreating} />
      <ExpenseDialog
        vehicleId={vehicleId}
        open={editing !== null}
        onOpenChange={(o) => !o && setEditing(null)}
        initial={editing}
      />
      <ConfirmDelete
        open={deleting !== null}
        onOpenChange={(o) => !o && setDeleting(null)}
        title="Excluir despesa?"
        description={`"${deleting?.description ?? ""}" será removida, junto com a transação gerada em Finanças.`}
        onConfirm={async () => {
          if (deleting) await remove.mutateAsync(deleting.id);
        }}
      />
    </>
  );
}
