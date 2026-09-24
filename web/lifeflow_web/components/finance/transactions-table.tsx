"use client";

import { Lock, Pencil, Repeat, Trash2 } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { ColorDot } from "@/components/finance/shared";
import { formatCurrency, formatDate } from "@/lib/finance/format";
import type { Category, Person, Transaction } from "@/lib/finance/api";
import { cn } from "@/lib/utils";

const sourceLabel: Record<string, string> = {
  maintenance: "Manutenção",
  refueling: "Abastecimento",
  vehicle_expense: "Despesa do veículo",
  recurring: "Recorrência",
};

export function TransactionsTable({
  transactions,
  categories,
  people,
  onEdit,
  onDelete,
}: {
  transactions: Transaction[];
  categories: Category[];
  people: Person[];
  onEdit?: (t: Transaction) => void;
  onDelete?: (t: Transaction) => void;
}) {
  const categoryById = new Map(categories.map((c) => [c.id, c]));
  const personById = new Map(people.map((p) => [p.id, p]));
  const actionable = Boolean(onEdit || onDelete);

  return (
    <Table>
      <TableHeader>
        <TableRow className="hover:bg-transparent">
          <TableHead className="w-28">Data</TableHead>
          <TableHead>Descrição</TableHead>
          <TableHead className="hidden md:table-cell">Categoria</TableHead>
          <TableHead className="hidden lg:table-cell">Pessoa</TableHead>
          <TableHead className="text-right">Valor</TableHead>
          {actionable && <TableHead className="w-24" />}
        </TableRow>
      </TableHeader>
      <TableBody>
        {transactions.map((t) => {
          const category = categoryById.get(t.category_id);
          const person = t.person_id ? personById.get(t.person_id) : undefined;
          const locked = t.source_type !== null;
          return (
            <TableRow key={t.id}>
              <TableCell className="text-muted-foreground">
                {formatDate(t.transaction_date)}
              </TableCell>
              <TableCell className="max-w-64 whitespace-normal">
                <div className="flex flex-wrap items-center gap-2">
                  <span className="font-medium">{t.description}</span>
                  {t.installment_total && (
                    <Badge variant="secondary">
                      {t.installment_index}/{t.installment_total}
                    </Badge>
                  )}
                  {t.source_type === "recurring" && (
                    <Repeat className="size-3.5 text-muted-foreground" aria-label="Recorrente" />
                  )}
                </div>
                {/* Em telas estreitas a categoria vai para baixo da descrição. */}
                <span className="mt-0.5 flex items-center gap-1.5 text-xs text-muted-foreground md:hidden">
                  <ColorDot color={category?.color ?? null} />
                  {category?.description ?? "Sem categoria"}
                </span>
              </TableCell>
              <TableCell className="hidden md:table-cell">
                <span className="flex items-center gap-2">
                  <ColorDot color={category?.color ?? null} />
                  {category?.description ?? "Sem categoria"}
                </span>
              </TableCell>
              <TableCell className="hidden text-muted-foreground lg:table-cell">
                {person?.name ?? "—"}
              </TableCell>
              <TableCell
                className={cn(
                  "text-right font-medium tabular-nums",
                  t.type === "income" ? "text-primary" : "text-foreground",
                )}
              >
                {t.type === "income" ? "+" : "−"} {formatCurrency(t.amount)}
              </TableCell>
              {actionable && (
                <TableCell className="text-right">
                  {locked ? (
                    <span
                      className="inline-flex size-7 items-center justify-center text-muted-foreground"
                      title={`Gerada por: ${sourceLabel[t.source_type!] ?? "origem automática"}. Só pode ser alterada pela origem.`}
                    >
                      <Lock className="size-3.5" />
                    </span>
                  ) : (
                    <>
                      {onEdit && (
                        <Button
                          variant="ghost"
                          size="icon-sm"
                          aria-label={`Editar ${t.description}`}
                          onClick={() => onEdit(t)}
                        >
                          <Pencil />
                        </Button>
                      )}
                      {onDelete && (
                        <Button
                          variant="ghost"
                          size="icon-sm"
                          aria-label={`Excluir ${t.description}`}
                          onClick={() => onDelete(t)}
                        >
                          <Trash2 />
                        </Button>
                      )}
                    </>
                  )}
                </TableCell>
              )}
            </TableRow>
          );
        })}
      </TableBody>
    </Table>
  );
}
