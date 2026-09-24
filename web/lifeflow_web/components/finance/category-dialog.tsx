"use client";

import { Controller, useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Input } from "@/components/ui/input";
import { Field, OptionSelect } from "@/components/finance/shared";
import { FormDialog, FormFooter, useSubmit } from "@/components/finance/form-dialog";
import { useSaveCategory } from "@/lib/finance/hooks";
import { categorySchema, type CategoryValues } from "@/lib/finance/schemas";
import type { Category } from "@/lib/finance/api";

const purposes = [
  { value: "both", label: "Despesa e receita" },
  { value: "expense", label: "Somente despesa" },
  { value: "income", label: "Somente receita" },
];

export function CategoryDialog({
  open,
  onOpenChange,
  initial,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  initial?: Category | null;
}) {
  return (
    <FormDialog
      open={open}
      onOpenChange={onOpenChange}
      title={initial ? "Editar categoria" : "Nova categoria"}
    >
      <CategoryForm initial={initial} onClose={() => onOpenChange(false)} />
    </FormDialog>
  );
}

function CategoryForm({
  initial,
  onClose,
}: {
  initial?: Category | null;
  onClose: () => void;
}) {
  const save = useSaveCategory();
  const { pending, error, run } = useSubmit(onClose);
  const {
    register,
    control,
    handleSubmit,
    formState: { errors },
  } = useForm<CategoryValues>({
    resolver: zodResolver(categorySchema),
    defaultValues: {
      description: initial?.description ?? "",
      purpose: (initial?.purpose as CategoryValues["purpose"]) ?? "both",
      color: initial?.color ?? "",
    },
  });

  return (
    <form
      className="flex flex-col gap-4"
      onSubmit={handleSubmit((values) =>
        run(() => save.mutateAsync({ id: initial?.id ?? null, values })),
      )}
    >
      <Field label="Descrição" error={errors.description?.message}>
        <Input placeholder="Ex.: Mercado" maxLength={80} autoFocus {...register("description")} />
      </Field>
      <Field label="Tipo">
        <Controller
          control={control}
          name="purpose"
          render={({ field }) => (
            <OptionSelect
              value={field.value}
              onChange={field.onChange}
              options={purposes}
            />
          )}
        />
      </Field>
      <Field label="Cor (opcional)" error={errors.color?.message}>
        <Input placeholder="#61E786" maxLength={7} {...register("color")} />
      </Field>
      <FormFooter
        pending={pending}
        error={error}
        submitLabel={initial ? "Salvar alterações" : "Salvar categoria"}
        onCancel={onClose}
      />
    </form>
  );
}
