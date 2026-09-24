"use client";

import { useState } from "react";
import { Pencil, Plus, Trash2 } from "lucide-react";
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
import { PersonDialog } from "@/components/finance/person-dialog";
import {
  ConfirmDelete,
  EmptyState,
  ErrorState,
  LoadingRows,
  PageHeader,
} from "@/components/finance/shared";
import { useDeletePerson, usePeople } from "@/lib/finance/hooks";
import { formatDate } from "@/lib/finance/format";
import type { Person } from "@/lib/finance/api";

export function PeopleScreen() {
  const people = usePeople();
  const remove = useDeletePerson();
  const [creating, setCreating] = useState(false);
  const [editing, setEditing] = useState<Person | null>(null);
  const [deleting, setDeleting] = useState<Person | null>(null);

  const active = (people.data ?? []).filter((p) => p.deleted_at === null);

  return (
    <div className="mx-auto flex max-w-3xl flex-col gap-6">
      <PageHeader
        title="Pessoas"
        description="Vincule transações a quem elas pertencem."
        actions={
          <Button onClick={() => setCreating(true)}>
            <Plus /> Nova pessoa
          </Button>
        }
      />
      <Card className="p-2 sm:p-4">
        {people.isPending ? (
          <LoadingRows />
        ) : people.isError ? (
          <ErrorState
            message="Não foi possível carregar as pessoas."
            onRetry={() => void people.refetch()}
          />
        ) : active.length === 0 ? (
          <EmptyState
            title="Nenhuma pessoa cadastrada."
            description="Cadastre pessoas para ver quanto cada uma gasta ou recebe."
            action={
              <Button onClick={() => setCreating(true)}>
                <Plus /> Nova pessoa
              </Button>
            }
          />
        ) : (
          <Table>
            <TableHeader>
              <TableRow className="hover:bg-transparent">
                <TableHead>Nome</TableHead>
                <TableHead>Nascimento</TableHead>
                <TableHead className="w-24" />
              </TableRow>
            </TableHeader>
            <TableBody>
              {active.map((p) => (
                <TableRow key={p.id}>
                  <TableCell className="font-medium">{p.name}</TableCell>
                  <TableCell className="text-muted-foreground">
                    {p.birth_date ? formatDate(p.birth_date) : "—"}
                  </TableCell>
                  <TableCell className="text-right">
                    <Button
                      variant="ghost"
                      size="icon-sm"
                      aria-label={`Editar ${p.name}`}
                      onClick={() => setEditing(p)}
                    >
                      <Pencil />
                    </Button>
                    <Button
                      variant="ghost"
                      size="icon-sm"
                      aria-label={`Excluir ${p.name}`}
                      onClick={() => setDeleting(p)}
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

      <PersonDialog open={creating} onOpenChange={setCreating} />
      <PersonDialog
        open={editing !== null}
        onOpenChange={(open) => !open && setEditing(null)}
        initial={editing}
      />
      <ConfirmDelete
        open={deleting !== null}
        onOpenChange={(open) => !open && setDeleting(null)}
        title="Excluir pessoa?"
        description={`“${deleting?.name ?? ""}” deixa de aparecer nas listas; as transações já vinculadas continuam registradas.`}
        onConfirm={async () => {
          if (deleting) await remove.mutateAsync(deleting.id);
        }}
      />
    </div>
  );
}
