"use client";

import { Controller, useForm, useWatch } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Input } from "@/components/ui/input";
import { Switch } from "@/components/ui/switch";
import { Field, OptionSelect, Segmented } from "@/components/finance/shared";
import { FormDialog, FormFooter, useSubmit } from "@/components/finance/form-dialog";
import { useCategories, usePeople, useSaveRecurring } from "@/lib/finance/hooks";
import { moneyToInput, todayIso } from "@/lib/finance/format";
import { categoryOptions, personOptions } from "@/lib/finance/options";
import { recurringSchema, type RecurringValues } from "@/lib/finance/schemas";
import type { RecurringTransaction } from "@/lib/finance/api";

/** Edição de uma recorrência existente; a criação é feita pelo diálogo de transação. */
export function RecurringDialog({
  open,
  onOpenChange,
  initial,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  initial: RecurringTransaction | null;
}) {
  return (
    <FormDialog
      open={open}
      onOpenChange={onOpenChange}
      title="Editar recorrência"
      className="sm:max-w-md"
    >
      {initial && <RecurringForm initial={initial} onClose={() => onOpenChange(false)} />}
    </FormDialog>
  );
}

function RecurringForm({
  initial,
  onClose,
}: {
  initial: RecurringTransaction;
  onClose: () => void;
}) {
  const categories = useCategories();
  const people = usePeople();
  const save = useSaveRecurring();
  const { pending, error, run } = useSubmit(onClose);

  const {
    register,
    control,
    setValue,
    handleSubmit,
    formState: { errors },
  } = useForm<RecurringValues>({
    resolver: zodResolver(recurringSchema),
    defaultValues: {
      type: initial.type as RecurringValues["type"],
      description: initial.description,
      categoryId: initial.category_id,
      personId: initial.person_id ?? "",
      amount: moneyToInput(initial.amount),
      dayOfMonth: String(initial.day_of_month),
      startDate: initial.start_date,
      endDate: initial.end_date ?? "",
      paused: initial.paused,
    },
  });

  const type = useWatch({ control, name: "type" });
  const categoryId = useWatch({ control, name: "categoryId" });

  return (
    <form
      className="flex flex-col gap-4"
      onSubmit={handleSubmit((values) => run(() => save.mutateAsync({ id: initial.id, values })))}
    >
      <Controller
        control={control}
        name="type"
        render={({ field }) => (
          <Segmented
            value={field.value}
            onChange={(next) => {
              field.onChange(next);
              const ok = categoryOptions(categories.data ?? [], next, initial.category_id).some(
                (o) => o.value === categoryId,
              );
              if (!ok) setValue("categoryId", "");
            }}
            options={[
              { value: "expense", label: "Despesa" },
              { value: "income", label: "Receita" },
            ]}
          />
        )}
      />
      <Field label="Descrição" error={errors.description?.message}>
        <Input maxLength={160} autoFocus {...register("description")} />
      </Field>
      <div className="grid grid-cols-2 gap-3">
        <Field label="Categoria" error={errors.categoryId?.message}>
          <Controller
            control={control}
            name="categoryId"
            render={({ field }) => (
              <OptionSelect
                value={field.value}
                onChange={field.onChange}
                options={categoryOptions(categories.data ?? [], type, initial.category_id)}
                invalid={Boolean(errors.categoryId)}
              />
            )}
          />
        </Field>
        <Field label="Pessoa (opcional)">
          <Controller
            control={control}
            name="personId"
            render={({ field }) => (
              <OptionSelect
                value={field.value}
                onChange={field.onChange}
                options={personOptions(people.data ?? [], initial.person_id ?? undefined)}
                emptyLabel="Ninguém"
              />
            )}
          />
        </Field>
      </div>
      <div className="grid grid-cols-2 gap-3">
        <Field label="Valor" error={errors.amount?.message}>
          <Input inputMode="decimal" {...register("amount")} />
        </Field>
        <Field label="Dia do mês" error={errors.dayOfMonth?.message}>
          <Input inputMode="numeric" {...register("dayOfMonth")} />
        </Field>
        <Field label="Início" error={errors.startDate?.message}>
          <Input type="date" {...register("startDate")} />
        </Field>
        <Field label="Fim (opcional)" error={errors.endDate?.message}>
          <Input type="date" min={todayIso() < initial.start_date ? initial.start_date : undefined} {...register("endDate")} />
        </Field>
      </div>
      <Controller
        control={control}
        name="paused"
        render={({ field }) => (
          <label className="flex items-center justify-between gap-3 text-sm">
            <span>
              <span className="font-medium">Pausada</span>
              <span className="block text-muted-foreground">
                Não gera novas ocorrências enquanto pausada
              </span>
            </span>
            <Switch checked={field.value} onCheckedChange={field.onChange} />
          </label>
        )}
      />
      <FormFooter pending={pending} error={error} submitLabel="Salvar alterações" onCancel={onClose} />
    </form>
  );
}
