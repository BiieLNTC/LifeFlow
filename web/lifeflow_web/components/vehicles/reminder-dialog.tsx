"use client";

import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Input } from "@/components/ui/input";
import { Field } from "@/components/finance/shared";
import { FormDialog, FormFooter, useSubmit } from "@/components/finance/form-dialog";
import { FieldRow } from "@/components/vehicles/shared";
import { useSaveReminder } from "@/lib/vehicles/hooks";
import { reminderSchema, type ReminderValues } from "@/lib/vehicles/schemas";
import type { Reminder } from "@/lib/vehicles/api";

export function ReminderDialog({
  vehicleId,
  open,
  onOpenChange,
  initial,
}: {
  vehicleId: string;
  open: boolean;
  onOpenChange: (open: boolean) => void;
  initial?: Reminder | null;
}) {
  return (
    <FormDialog
      open={open}
      onOpenChange={onOpenChange}
      title={initial ? "Editar lembrete" : "Novo lembrete"}
      description="Acompanhe por quilometragem, por data ou pelos dois — vale o que chegar primeiro."
    >
      <ReminderForm vehicleId={vehicleId} initial={initial} onClose={() => onOpenChange(false)} />
    </FormDialog>
  );
}

function ReminderForm({
  vehicleId,
  initial,
  onClose,
}: {
  vehicleId: string;
  initial?: Reminder | null;
  onClose: () => void;
}) {
  const save = useSaveReminder();
  const { pending, error, run } = useSubmit(onClose);
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<ReminderValues>({
    resolver: zodResolver(reminderSchema),
    defaultValues: {
      description: initial?.description ?? "",
      targetOdometer: initial?.target_odometer != null ? String(initial.target_odometer) : "",
      targetDate: initial?.target_date ?? "",
    },
  });

  return (
    <form
      className="flex flex-col gap-4"
      onSubmit={handleSubmit((values) =>
        run(() => save.mutateAsync({ vehicleId, id: initial?.id ?? null, values })),
      )}
    >
      <Field label="Descrição" error={errors.description?.message}>
        <Input
          placeholder="Ex.: Trocar óleo do motor"
          maxLength={160}
          autoFocus
          {...register("description")}
        />
      </Field>
      <FieldRow>
        <Field label="Na quilometragem (km)" error={errors.targetOdometer?.message}>
          <Input inputMode="numeric" {...register("targetOdometer")} />
        </Field>
        <Field label="Na data" error={errors.targetDate?.message}>
          <Input type="date" {...register("targetDate")} />
        </Field>
      </FieldRow>
      <FormFooter
        pending={pending}
        error={error}
        submitLabel={initial ? "Salvar alterações" : "Salvar lembrete"}
        onCancel={onClose}
      />
    </form>
  );
}
