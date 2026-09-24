"use client";

import { useState } from "react";
import { Pencil, Plus, Trash2 } from "lucide-react";
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
import { CategoryDialog } from "@/components/finance/category-dialog";
import {
  ColorDot,
  ConfirmDelete,
  EmptyState,
  ErrorState,
  LoadingRows,
  PageHeader,
  purposeLabel,
} from "@/components/finance/shared";
import { useCategories, useDeleteCategory } from "@/lib/finance/hooks";
import type { Category } from "@/lib/finance/api";

export function CategoriesScreen() {
  const categories = useCategories();
  const remove = useDeleteCategory();
  const [creating, setCreating] = useState(false);
  const [editing, setEditing] = useState<Category | null>(null);
  const [deleting, setDeleting] = useState<Category | null>(null);

  const active = (categories.data ?? []).filter((c) => c.deleted_at === null);

  return (
    <div className="mx-auto flex max-w-3xl flex-col gap-6">
      <PageHeader
        title="Categorias"
        description="Organize suas receitas e despesas."
        actions={
          <Button onClick={() => setCreating(true)}>
            <Plus /> Nova categoria
          </Button>
        }
      />
      <Card className="p-2 sm:p-4">
        {categories.isPending ? (
          <LoadingRows />
        ) : categories.isError ? (
          <ErrorState
            message="Não foi possível carregar as categorias."
            onRetry={() => void categories.refetch()}
          />
        ) : active.length === 0 ? (
          <EmptyState
            title="Nenhuma categoria cadastrada."
            description="Crie categorias como Mercado, Salário ou Lazer para classificar as transações."
            action={
              <Button onClick={() => setCreating(true)}>
                <Plus /> Nova categoria
              </Button>
            }
          />
        ) : (
          <Table>
            <TableHeader>
              <TableRow className="hover:bg-transparent">
                <TableHead>Categoria</TableHead>
                <TableHead>Tipo</TableHead>
                <TableHead className="w-24" />
              </TableRow>
            </TableHeader>
            <TableBody>
              {active.map((c) => (
                <TableRow key={c.id}>
                  <TableCell>
                    <span className="flex items-center gap-2 font-medium">
                      <ColorDot color={c.color} />
                      {c.description}
                    </span>
                  </TableCell>
                  <TableCell>
                    <Badge variant="secondary">
                      {purposeLabel[c.purpose as keyof typeof purposeLabel]}
                    </Badge>
                  </TableCell>
                  <TableCell className="text-right">
                    <Button
                      variant="ghost"
                      size="icon-sm"
                      aria-label={`Editar ${c.description}`}
                      onClick={() => setEditing(c)}
                    >
                      <Pencil />
                    </Button>
                    <Button
                      variant="ghost"
                      size="icon-sm"
                      aria-label={`Excluir ${c.description}`}
                      onClick={() => setDeleting(c)}
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

      <CategoryDialog open={creating} onOpenChange={setCreating} />
      <CategoryDialog
        open={editing !== null}
        onOpenChange={(open) => !open && setEditing(null)}
        initial={editing}
      />
      <ConfirmDelete
        open={deleting !== null}
        onOpenChange={(open) => !open && setDeleting(null)}
        title="Excluir categoria?"
        description={`“${deleting?.description ?? ""}” deixa de aparecer nas listas; as transações já registradas continuam com ela.`}
        onConfirm={async () => {
          if (deleting) await remove.mutateAsync(deleting.id);
        }}
      />
    </div>
  );
}
