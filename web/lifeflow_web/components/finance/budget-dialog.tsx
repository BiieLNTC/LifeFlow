"use client";

import { Controller, useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Input } from "@/components/ui/input";
import { Field, OptionSelect } from "@/components/finance/shared";
import { FormDialog, FormFooter, useSubmit } from "@/components/finance/form-dialog";
import { useCategories, useSaveBudget } from "@/lib/finance/hooks";
import { moneyToInput, monthLabel } from "@/lib/finance/format";
import { categoryOptions } from "@/lib/finance/options";
import { budgetSchema, type BudgetValues } from "@/lib/finance/schemas";
import type { BudgetProgress } from "@/lib/finance/api";

export function BudgetDialog({
  open,
  onOpenChange,
  period,
  initial,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  period: { year: number; month: number };
  initial?: BudgetProgress | null;
}) {
  return (
    <FormDialog
      open={open}
      onOpenChange={onOpenChange}
      title={initial ? "Editar orçamento" : "Novo orçamento"}
      description={monthLabel(period.year, period.month)}
    >
      <BudgetForm period={period} initial={initial} onClose={() => onOpenChange(false)} />
    </FormDialog>
  );
}

function BudgetForm({
  period,
  initial,
  onClose,
}: {
  period: { year: number; month: number };
  initial?: BudgetProgress | null;
  onClose: () => void;
}) {
  const categories = useCategories();
  const save = useSaveBudget();
  const { pending, error, run } = useSubmit(onClose);
  const {
    register,
    control,
    handleSubmit,
    formState: { errors },
  } = useForm<BudgetValues>({
    resolver: zodResolver(budgetSchema),
    defaultValues: {
      categoryId: initial?.category_id ?? "",
      limitAmount: initial?.limit_amount != null ? moneyToInput(initial.limit_amount) : "",
    },
  });

  return (
    <form
      className="flex flex-col gap-4"
      onSubmit={handleSubmit((values) =>
        run(() => save.mutateAsync({ id: initial?.budget_id ?? null, period, values })),
      )}
    >
      <Field label="Categoria" error={errors.categoryId?.message}>
        <Controller
          control={control}
          name="categoryId"
          render={({ field }) => (
            <OptionSelect
              value={field.value}
              onChange={field.onChange}
              // Orçamento controla gasto: só categorias de despesa.
              options={categoryOptions(categories.data ?? [], "expense", initial?.category_id ?? undefined)}
              invalid={Boolean(errors.categoryId)}
            />
          )}
        />
      </Field>
      <Field label="Limite do mês" error={errors.limitAmount?.message}>
        <Input inputMode="decimal" placeholder="0,00" autoFocus {...register("limitAmount")} />
      </Field>
      <FormFooter
        pending={pending}
        error={error}
        submitLabel={initial ? "Salvar alterações" : "Salvar orçamento"}
        onCancel={onClose}
      />
    </form>
  );
}
