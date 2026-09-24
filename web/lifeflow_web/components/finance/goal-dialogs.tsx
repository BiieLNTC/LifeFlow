"use client";

import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Input } from "@/components/ui/input";
import { Field } from "@/components/finance/shared";
import { FormDialog, FormFooter, useSubmit } from "@/components/finance/form-dialog";
import { useAddContribution, useSaveGoal } from "@/lib/finance/hooks";
import { moneyToInput, todayIso } from "@/lib/finance/format";
import {
  contributionSchema,
  goalSchema,
  type ContributionValues,
  type GoalValues,
} from "@/lib/finance/schemas";
import type { SavingsGoal } from "@/lib/finance/api";

export function GoalDialog({
  open,
  onOpenChange,
  initial,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  initial?: SavingsGoal | null;
}) {
  return (
    <FormDialog
      open={open}
      onOpenChange={onOpenChange}
      title={initial ? "Editar meta" : "Nova meta"}
    >
      <GoalForm initial={initial} onClose={() => onOpenChange(false)} />
    </FormDialog>
  );
}

function GoalForm({ initial, onClose }: { initial?: SavingsGoal | null; onClose: () => void }) {
  const save = useSaveGoal();
  const { pending, error, run } = useSubmit(onClose);
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<GoalValues>({
    resolver: zodResolver(goalSchema),
    defaultValues: {
      title: initial?.title ?? "",
      targetAmount: initial ? moneyToInput(initial.target_amount) : "",
      targetDate: initial?.target_date ?? "",
    },
  });

  return (
    <form
      className="flex flex-col gap-4"
      onSubmit={handleSubmit((values) =>
        run(() => save.mutateAsync({ id: initial?.id ?? null, values })),
      )}
    >
      <Field label="Título" error={errors.title?.message}>
        <Input placeholder="Ex.: Viagem de férias" maxLength={120} autoFocus {...register("title")} />
      </Field>
      <div className="grid grid-cols-2 gap-3">
        <Field label="Valor alvo" error={errors.targetAmount?.message}>
          <Input inputMode="decimal" placeholder="0,00" {...register("targetAmount")} />
        </Field>
        <Field label="Data alvo (opcional)" error={errors.targetDate?.message}>
          <Input type="date" {...register("targetDate")} />
        </Field>
      </div>
      <FormFooter
        pending={pending}
        error={error}
        submitLabel={initial ? "Salvar alterações" : "Salvar meta"}
        onCancel={onClose}
      />
    </form>
  );
}

export function ContributionDialog({
  open,
  onOpenChange,
  goal,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  goal: SavingsGoal;
}) {
  return (
    <FormDialog
      open={open}
      onOpenChange={onOpenChange}
      title="Novo aporte"
      description={goal.title}
    >
      <ContributionForm goalId={goal.id} onClose={() => onOpenChange(false)} />
    </FormDialog>
  );
}

function ContributionForm({ goalId, onClose }: { goalId: string; onClose: () => void }) {
  const add = useAddContribution();
  const { pending, error, run } = useSubmit(onClose);
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<ContributionValues>({
    resolver: zodResolver(contributionSchema),
    defaultValues: { amount: "", date: todayIso() },
  });

  return (
    <form
      className="flex flex-col gap-4"
      onSubmit={handleSubmit((values) => run(() => add.mutateAsync({ goalId, values })))}
    >
      <div className="grid grid-cols-2 gap-3">
        <Field label="Valor" error={errors.amount?.message}>
          <Input inputMode="decimal" placeholder="0,00" autoFocus {...register("amount")} />
        </Field>
        <Field label="Data" error={errors.date?.message}>
          <Input type="date" max={todayIso()} {...register("date")} />
        </Field>
      </div>
      <FormFooter pending={pending} error={error} submitLabel="Registrar aporte" onCancel={onClose} />
    </form>
  );
}
