"use client";

import { Pencil, Plus, Trash2 } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { EmptyState, ErrorState, LoadingRows, PageHeader } from "@/components/finance/shared";
import { Textarea } from "@/components/ui/textarea";
import { cn } from "@/lib/utils";
import { urgencyLabels, type Urgency } from "@/lib/vehicles/options";

export function RowActions({
  label,
  onEdit,
  onDelete,
}: {
  label: string;
  onEdit?: () => void;
  onDelete?: () => void;
}) {
  return (
    <div className="flex justify-end">
      {onEdit && (
        <Button variant="ghost" size="icon-sm" aria-label={`Editar ${label}`} onClick={onEdit}>
          <Pencil />
        </Button>
      )}
      {onDelete && (
        <Button variant="ghost" size="icon-sm" aria-label={`Excluir ${label}`} onClick={onDelete}>
          <Trash2 />
        </Button>
      )}
    </div>
  );
}

const urgencyClass: Record<Urgency, string> = {
  overdue: "bg-critical/10 text-critical",
  near: "bg-warning/10 text-warning",
  upcoming: "bg-primary/10 text-primary",
  completed: "bg-muted text-muted-foreground",
};

/** Estado de vencimento: vermelho só para vencido, âmbar para próximo (DESIGN.md). */
export function UrgencyBadge({ status }: { status: Urgency }) {
  return (
    <Badge variant="ghost" className={cn("border-0", urgencyClass[status])}>
      {urgencyLabels[status]}
    </Badge>
  );
}

/** Urgência de um documento pela data de vencimento (mesmos limiares dos lembretes). */
export function documentUrgency(daysLeft: number | null): Urgency {
  if (daysLeft === null) return "upcoming";
  if (daysLeft < 0) return "overdue";
  if (daysLeft <= 30) return "near";
  return "upcoming";
}

export function NotesField(props: React.ComponentProps<typeof Textarea>) {
  return <Textarea rows={3} maxLength={2000} {...props} />;
}

/** Dois campos lado a lado em telas médias, empilhados no celular. */
export function FieldRow({ children }: { children: React.ReactNode }) {
  return <div className="grid gap-3 sm:grid-cols-2">{children}</div>;
}

export function StatTile({
  label,
  value,
  hint,
}: {
  label: string;
  value: string;
  hint?: string;
}) {
  return (
    <div className="flex flex-col gap-1">
      <span className="text-xs font-semibold tracking-widest text-muted-foreground uppercase">
        {label}
      </span>
      <span className="font-heading text-2xl font-bold tabular-nums">{value}</span>
      {hint && <span className="text-xs text-muted-foreground">{hint}</span>}
    </div>
  );
}

/**
 * Casca das telas de listagem do veículo: cabeçalho com ação, estados de
 * carregando/erro/vazio e o conteúdo dentro de um Card.
 */
export function ListSection({
  title,
  description,
  actionLabel,
  onAction,
  query,
  isEmpty,
  emptyTitle,
  emptyDescription,
  errorMessage,
  children,
}: {
  title: string;
  description?: string;
  actionLabel: string;
  onAction: () => void;
  query: { isPending: boolean; isError: boolean; refetch: () => unknown };
  isEmpty: boolean;
  emptyTitle: string;
  emptyDescription: string;
  errorMessage: string;
  children: React.ReactNode;
}) {
  const action = (
    <Button onClick={onAction}>
      <Plus /> {actionLabel}
    </Button>
  );
  return (
    <div className="flex flex-col gap-6">
      <PageHeader title={title} description={description} actions={action} />
      <Card className="p-2 sm:p-4">
        {query.isPending ? (
          <LoadingRows />
        ) : query.isError ? (
          <ErrorState message={errorMessage} onRetry={() => void query.refetch()} />
        ) : isEmpty ? (
          <EmptyState title={emptyTitle} description={emptyDescription} action={action} />
        ) : (
          children
        )}
      </Card>
    </div>
  );
}
