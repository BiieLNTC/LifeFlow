"use client";

import { Controller, useForm, useWatch } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Input } from "@/components/ui/input";
import { Field, OptionSelect, Segmented } from "@/components/finance/shared";
import { FormDialog, FormFooter, useSubmit } from "@/components/finance/form-dialog";
import { useCategories, usePeople, useSaveTransaction } from "@/lib/finance/hooks";
import { moneyToInput, todayIso } from "@/lib/finance/format";
import { categoryOptions, personOptions } from "@/lib/finance/options";
import { transactionSchema, type TransactionValues } from "@/lib/finance/schemas";
import type { Transaction } from "@/lib/finance/api";

/** `initial` = edição de uma transação existente (sempre modo "única"). */
export function TransactionDialog({
  open,
  onOpenChange,
  initial,
  defaultMode = "single",
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  initial?: Transaction | null;
  defaultMode?: TransactionValues["mode"];
}) {
  return (
    <FormDialog
      open={open}
      onOpenChange={onOpenChange}
      title={initial ? "Editar transação" : "Nova transação"}
      description={
        initial?.installment_total
          ? `Parcela ${initial.installment_index}/${initial.installment_total} — a edição afeta só esta parcela.`
          : undefined
      }
      className="sm:max-w-md"
    >
      <TransactionForm initial={initial} defaultMode={defaultMode} onClose={() => onOpenChange(false)} />
    </FormDialog>
  );
}

function TransactionForm({
  initial,
  defaultMode,
  onClose,
}: {
  initial?: Transaction | null;
  defaultMode: TransactionValues["mode"];
  onClose: () => void;
}) {
  const categories = useCategories();
  const people = usePeople();
  const save = useSaveTransaction();
  const { pending, error, run } = useSubmit(onClose);

  const {
    register,
    control,
    setValue,
    handleSubmit,
    formState: { errors },
  } = useForm<TransactionValues>({
    resolver: zodResolver(transactionSchema),
    defaultValues: {
      mode: defaultMode,
      type: (initial?.type as TransactionValues["type"]) ?? "expense",
      description: initial?.description ?? "",
      categoryId: initial?.category_id ?? "",
      personId: initial?.person_id ?? "",
      amount: initial ? moneyToInput(initial.amount) : "",
      date: initial?.transaction_date ?? todayIso(),
      installments: "2",
      dayOfMonth: String(new Date().getDate()).replace(/^(29|30|31)$/, "28"),
      endDate: "",
    },
  });

  const mode = useWatch({ control, name: "mode" });
  const type = useWatch({ control, name: "type" });
  const categoryId = useWatch({ control, name: "categoryId" });
  const editing = Boolean(initial);

  const catOptions = categoryOptions(categories.data ?? [], type, initial?.category_id);
  const peopleOptions = personOptions(people.data ?? [], initial?.person_id ?? undefined);

  return (
    <form
      className="flex flex-col gap-4"
      onSubmit={handleSubmit((values) =>
        run(() => save.mutateAsync({ id: initial?.id ?? null, values })),
      )}
    >
      {!editing && (
        <Controller
          control={control}
          name="mode"
          render={({ field }) => (
            <Segmented
              value={field.value}
              onChange={field.onChange}
              options={[
                { value: "single", label: "Única" },
                { value: "installment", label: "Parcelada" },
                { value: "recurring", label: "Recorrente" },
              ]}
            />
          )}
        />
      )}
      <Controller
        control={control}
        name="type"
        render={({ field }) => (
          <Segmented
            value={field.value}
            onChange={(next) => {
              field.onChange(next);
              // Troca de tipo pode invalidar a categoria escolhida.
              const stillValid = categoryOptions(categories.data ?? [], next, initial?.category_id).some(
                (o) => o.value === categoryId,
              );
              if (!stillValid) setValue("categoryId", "");
            }}
            options={[
              { value: "expense", label: "Despesa" },
              { value: "income", label: "Receita" },
            ]}
          />
        )}
      />

      <Field label="Descrição" error={errors.description?.message}>
        <Input
          placeholder="Ex.: Supermercado"
          maxLength={160}
          autoFocus
          {...register("description")}
        />
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
                options={catOptions}
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
                options={peopleOptions}
                emptyLabel="Ninguém"
              />
            )}
          />
        </Field>
      </div>

      <div className="grid grid-cols-2 gap-3">
        <Field
          label={mode === "installment" ? "Valor da parcela" : "Valor"}
          error={errors.amount?.message}
        >
          <Input inputMode="decimal" placeholder="0,00" {...register("amount")} />
        </Field>
        {mode === "recurring" ? (
          <Field label="Dia do mês" error={errors.dayOfMonth?.message}>
            <Input inputMode="numeric" {...register("dayOfMonth")} />
          </Field>
        ) : mode === "installment" ? (
          <Field label="Parcelas" error={errors.installments?.message}>
            <Input inputMode="numeric" {...register("installments")} />
          </Field>
        ) : (
          <Field label="Data" error={errors.date?.message}>
            <Input type="date" max={todayIso()} {...register("date")} />
          </Field>
        )}
      </div>

      {mode === "installment" && (
        <Field label="Data da primeira parcela" error={errors.date?.message}>
          <Input type="date" max={todayIso()} {...register("date")} />
        </Field>
      )}
      {mode === "recurring" && (
        <Field label="Repetir até (opcional)" error={errors.endDate?.message}>
          <Input type="date" min={todayIso()} {...register("endDate")} />
        </Field>
      )}

      <FormFooter
        pending={pending}
        error={error}
        submitLabel={
          editing
            ? "Salvar alterações"
            : mode === "installment"
              ? "Criar parcelas"
              : mode === "recurring"
                ? "Criar recorrência"
                : "Salvar transação"
        }
        onCancel={onClose}
      />
    </form>
  );
}
