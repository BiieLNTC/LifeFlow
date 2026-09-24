"use client";

import { Controller, useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Input } from "@/components/ui/input";
import { Field, OptionSelect } from "@/components/finance/shared";
import { FormDialog, FormFooter, useSubmit } from "@/components/finance/form-dialog";
import { FieldRow, NotesField } from "@/components/vehicles/shared";
import { moneyToInput, todayIso } from "@/lib/finance/format";
import { useSaveExpense } from "@/lib/vehicles/hooks";
import { expenseSchema, type ExpenseValues } from "@/lib/vehicles/schemas";
import { expenseCategoryOptions } from "@/lib/vehicles/options";
import type { Expense } from "@/lib/vehicles/api";

export function ExpenseDialog({
  vehicleId,
  open,
  onOpenChange,
  initial,
}: {
  vehicleId: string;
  open: boolean;
  onOpenChange: (open: boolean) => void;
  initial?: Expense | null;
}) {
  return (
    <FormDialog
      open={open}
      onOpenChange={onOpenChange}
      title={initial ? "Editar despesa" : "Nova despesa"}
      description="Também aparece em Finanças como transação gerada automaticamente."
    >
      <ExpenseForm vehicleId={vehicleId} initial={initial} onClose={() => onOpenChange(false)} />
    </FormDialog>
  );
}

function ExpenseForm({
  vehicleId,
  initial,
  onClose,
}: {
  vehicleId: string;
  initial?: Expense | null;
  onClose: () => void;
}) {
  const save = useSaveExpense();
  const { pending, error, run } = useSubmit(onClose);
  const {
    register,
    control,
    handleSubmit,
    formState: { errors },
  } = useForm<ExpenseValues>({
    resolver: zodResolver(expenseSchema),
    defaultValues: {
      date: initial?.expense_date ?? todayIso(),
      category: initial?.category ?? "",
      description: initial?.description ?? "",
      amount: initial ? moneyToInput(initial.amount) : "",
      notes: initial?.notes ?? "",
    },
  });

  return (
    <form
      className="flex flex-col gap-4"
      onSubmit={handleSubmit((values) =>
        run(() => save.mutateAsync({ vehicleId, id: initial?.id ?? null, values })),
      )}
    >
      <FieldRow>
        <Field label="Categoria" error={errors.category?.message}>
          <Controller
            control={control}
            name="category"
            render={({ field }) => (
              <OptionSelect
                value={field.value}
                onChange={field.onChange}
                options={expenseCategoryOptions}
                invalid={Boolean(errors.category)}
              />
            )}
          />
        </Field>
        <Field label="Data" error={errors.date?.message}>
          <Input type="date" max={todayIso()} {...register("date")} />
        </Field>
      </FieldRow>
      <Field label="Descrição" error={errors.description?.message}>
        <Input maxLength={160} autoFocus {...register("description")} />
      </Field>
      <Field label="Valor" error={errors.amount?.message}>
        <Input inputMode="decimal" placeholder="0,00" {...register("amount")} />
      </Field>
      <Field label="Observações (opcional)" error={errors.notes?.message}>
        <NotesField {...register("notes")} />
      </Field>
      <FormFooter
        pending={pending}
        error={error}
        submitLabel={initial ? "Salvar alterações" : "Salvar despesa"}
        onCancel={onClose}
      />
    </form>
  );
}
