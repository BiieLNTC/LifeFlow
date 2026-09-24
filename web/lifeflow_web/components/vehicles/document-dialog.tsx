"use client";

import { Controller, useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Input } from "@/components/ui/input";
import { Field, OptionSelect } from "@/components/finance/shared";
import { FormDialog, FormFooter, useSubmit } from "@/components/finance/form-dialog";
import { FieldRow } from "@/components/vehicles/shared";
import { todayIso } from "@/lib/finance/format";
import { useSaveDocument } from "@/lib/vehicles/hooks";
import { documentSchema, type DocumentValues } from "@/lib/vehicles/schemas";
import { documentTypeOptions, type DocumentType } from "@/lib/vehicles/options";
import type { VehicleDocument } from "@/lib/vehicles/api";

export function DocumentDialog({
  vehicleId,
  open,
  onOpenChange,
  initial,
}: {
  vehicleId: string;
  open: boolean;
  onOpenChange: (open: boolean) => void;
  initial?: VehicleDocument | null;
}) {
  return (
    <FormDialog
      open={open}
      onOpenChange={onOpenChange}
      title={initial ? "Editar documento" : "Novo documento"}
      description="Guarda só a data de vencimento — o arquivo não é armazenado."
    >
      <DocumentForm vehicleId={vehicleId} initial={initial} onClose={() => onOpenChange(false)} />
    </FormDialog>
  );
}

function DocumentForm({
  vehicleId,
  initial,
  onClose,
}: {
  vehicleId: string;
  initial?: VehicleDocument | null;
  onClose: () => void;
}) {
  const save = useSaveDocument();
  const { pending, error, run } = useSubmit(onClose);
  const {
    register,
    control,
    handleSubmit,
    formState: { errors },
  } = useForm<DocumentValues>({
    resolver: zodResolver(documentSchema),
    defaultValues: {
      type: (initial?.type as DocumentType | undefined) ?? "insurance",
      description: initial?.description ?? "",
      issueDate: initial?.issue_date ?? "",
      expiryDate: initial?.expiry_date ?? "",
    },
  });

  return (
    <form
      className="flex flex-col gap-4"
      onSubmit={handleSubmit((values) =>
        run(() => save.mutateAsync({ vehicleId, id: initial?.id ?? null, values })),
      )}
    >
      <Field label="Tipo" error={errors.type?.message}>
        <Controller
          control={control}
          name="type"
          render={({ field }) => (
            <OptionSelect
              value={field.value}
              onChange={field.onChange}
              options={documentTypeOptions}
            />
          )}
        />
      </Field>
      <Field label="Descrição" error={errors.description?.message}>
        <Input
          placeholder="Ex.: Seguro Porto — apólice 123"
          maxLength={160}
          autoFocus
          {...register("description")}
        />
      </Field>
      <FieldRow>
        <Field label="Emissão (opcional)" error={errors.issueDate?.message}>
          <Input type="date" max={todayIso()} {...register("issueDate")} />
        </Field>
        <Field label="Vencimento (opcional)" error={errors.expiryDate?.message}>
          <Input type="date" {...register("expiryDate")} />
        </Field>
      </FieldRow>
      <FormFooter
        pending={pending}
        error={error}
        submitLabel={initial ? "Salvar alterações" : "Salvar documento"}
        onCancel={onClose}
      />
    </form>
  );
}
