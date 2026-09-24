"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { ArrowLeft, Pencil, Plus, Trash2 } from "lucide-react";
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
import { ContributionDialog, GoalDialog } from "@/components/finance/goal-dialogs";
import { GoalSummary } from "@/components/finance/goals-screen";
import {
  ConfirmDelete,
  EmptyState,
  ErrorState,
  LoadingRows,
  PageHeader,
  SectionTitle,
} from "@/components/finance/shared";
import { useDeleteContribution, useDeleteGoal, useGoals } from "@/lib/finance/hooks";
import { formatCurrency, formatDate } from "@/lib/finance/format";

export function GoalDetailScreen({ goalId }: { goalId: string }) {
  const router = useRouter();
  const goals = useGoals();
  const removeGoal = useDeleteGoal();
  const removeContribution = useDeleteContribution();
  const [editing, setEditing] = useState(false);
  const [contributing, setContributing] = useState(false);
  const [deletingGoal, setDeletingGoal] = useState(false);
  const [deletingContribution, setDeletingContribution] = useState<string | null>(null);

  const goal = goals.data?.find((g) => g.id === goalId);
  const contributions = [...(goal?.goal_contributions ?? [])].sort((a, b) =>
    b.contribution_date.localeCompare(a.contribution_date),
  );

  const back = (
    <Link
      href="/finance/goals"
      className="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground"
    >
      <ArrowLeft className="size-4" /> Metas
    </Link>
  );

  if (goals.isPending) {
    return (
      <div className="flex flex-col gap-6">
        {back}
        <LoadingRows rows={3} />
      </div>
    );
  }
  if (goals.isError) {
    return (
      <div className="flex flex-col gap-6">
        {back}
        <ErrorState message="Não foi possível carregar a meta." onRetry={() => void goals.refetch()} />
      </div>
    );
  }
  if (!goal) {
    return (
      <div className="flex flex-col gap-6">
        {back}
        <EmptyState title="Meta não encontrada." description="Ela pode ter sido removida." />
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-6">
      {back}
      <PageHeader
        title={goal.title}
        actions={
          <>
            <Button variant="outline" onClick={() => setEditing(true)}>
              <Pencil /> Editar
            </Button>
            <Button variant="outline" onClick={() => setDeletingGoal(true)}>
              <Trash2 /> Excluir
            </Button>
          </>
        }
      />

      <Card className="p-5">
        <GoalSummary goal={goal} />
      </Card>

      <div className="flex items-center justify-between">
        <SectionTitle>Aportes</SectionTitle>
        <Button onClick={() => setContributing(true)}>
          <Plus /> Novo aporte
        </Button>
      </div>

      <Card className="p-2 sm:p-4">
        {contributions.length === 0 ? (
          <EmptyState title="Nenhum aporte registrado." />
        ) : (
          <Table>
            <TableHeader>
              <TableRow className="hover:bg-transparent">
                <TableHead>Data</TableHead>
                <TableHead className="text-right">Valor</TableHead>
                <TableHead className="w-12" />
              </TableRow>
            </TableHeader>
            <TableBody>
              {contributions.map((c) => (
                <TableRow key={c.id}>
                  <TableCell>{formatDate(c.contribution_date)}</TableCell>
                  <TableCell className="text-right font-medium tabular-nums">
                    {formatCurrency(c.amount)}
                  </TableCell>
                  <TableCell className="text-right">
                    <Button
                      variant="ghost"
                      size="icon-sm"
                      aria-label={`Excluir aporte de ${formatCurrency(c.amount)}`}
                      onClick={() => setDeletingContribution(c.id)}
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

      <GoalDialog open={editing} onOpenChange={setEditing} initial={goal} />
      <ContributionDialog open={contributing} onOpenChange={setContributing} goal={goal} />
      <ConfirmDelete
        open={deletingGoal}
        onOpenChange={setDeletingGoal}
        title="Excluir meta?"
        description={`“${goal.title}” e o histórico de aportes deixarão de aparecer.`}
        onConfirm={async () => {
          await removeGoal.mutateAsync(goal.id);
          router.replace("/finance/goals");
        }}
      />
      <ConfirmDelete
        open={deletingContribution !== null}
        onOpenChange={(open) => !open && setDeletingContribution(null)}
        title="Excluir aporte?"
        description="O valor deixará de contar no progresso da meta."
        onConfirm={async () => {
          if (deletingContribution) await removeContribution.mutateAsync(deletingContribution);
        }}
      />
    </div>
  );
}
