"use client";

import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Input } from "@/components/ui/input";
import { Field } from "@/components/finance/shared";
import { FormDialog, FormFooter, useSubmit } from "@/components/finance/form-dialog";
import { useSavePerson } from "@/lib/finance/hooks";
import { todayIso } from "@/lib/finance/format";
import { personSchema, type PersonValues } from "@/lib/finance/schemas";
import type { Person } from "@/lib/finance/api";

export function PersonDialog({
  open,
  onOpenChange,
  initial,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  initial?: Person | null;
}) {
  return (
    <FormDialog
      open={open}
      onOpenChange={onOpenChange}
      title={initial ? "Editar pessoa" : "Nova pessoa"}
    >
      <PersonForm initial={initial} onClose={() => onOpenChange(false)} />
    </FormDialog>
  );
}

function PersonForm({
  initial,
  onClose,
}: {
  initial?: Person | null;
  onClose: () => void;
}) {
  const save = useSavePerson();
  const { pending, error, run } = useSubmit(onClose);
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<PersonValues>({
    resolver: zodResolver(personSchema),
    defaultValues: { name: initial?.name ?? "", birthDate: initial?.birth_date ?? "" },
  });

  return (
    <form
      className="flex flex-col gap-4"
      onSubmit={handleSubmit((values) =>
        run(() => save.mutateAsync({ id: initial?.id ?? null, values })),
      )}
    >
      <Field label="Nome" error={errors.name?.message}>
        <Input maxLength={120} autoFocus {...register("name")} />
      </Field>
      <Field label="Data de nascimento (opcional)" error={errors.birthDate?.message}>
        <Input type="date" max={todayIso()} {...register("birthDate")} />
      </Field>
      <FormFooter
        pending={pending}
        error={error}
        submitLabel={initial ? "Salvar alterações" : "Salvar pessoa"}
        onCancel={onClose}
      />
    </form>
  );
}
