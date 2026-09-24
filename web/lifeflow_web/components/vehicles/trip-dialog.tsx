"use client";

import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Input } from "@/components/ui/input";
import { Field } from "@/components/finance/shared";
import { FormDialog, FormFooter, useSubmit } from "@/components/finance/form-dialog";
import { FieldRow } from "@/components/vehicles/shared";
import { nowLocalInput } from "@/lib/vehicles/format";
import { useSaveTrip } from "@/lib/vehicles/hooks";
import { tripToValues, type Trip } from "@/lib/vehicles/api";
import { tripSchema, type TripValues } from "@/lib/vehicles/schemas";

/** `finish` encerra uma viagem em andamento (fim obrigatório); `edit` altera qualquer campo. */
export type TripMode = "start" | "edit" | "finish";

export function TripDialog({
  vehicleId,
  open,
  onOpenChange,
  mode,
  trip,
  currentOdometer,
}: {
  vehicleId: string;
  open: boolean;
  onOpenChange: (open: boolean) => void;
  mode: TripMode;
  trip?: Trip | null;
  currentOdometer?: number;
}) {
  const title =
    mode === "start" ? "Iniciar viagem" : mode === "finish" ? "Encerrar viagem" : "Editar viagem";
  return (
    <FormDialog
      open={open}
      onOpenChange={onOpenChange}
      title={title}
      description={
        mode === "finish"
          ? "Informe a quilometragem e o horário de chegada."
          : "Registre o hodômetro na saída; encerre a viagem ao chegar."
      }
    >
      <TripForm
        vehicleId={vehicleId}
        mode={mode}
        trip={trip}
        currentOdometer={currentOdometer}
        onClose={() => onOpenChange(false)}
      />
    </FormDialog>
  );
}

function TripForm({
  vehicleId,
  mode,
  trip,
  currentOdometer,
  onClose,
}: {
  vehicleId: string;
  mode: TripMode;
  trip?: Trip | null;
  currentOdometer?: number;
  onClose: () => void;
}) {
  const save = useSaveTrip();
  const { pending, error, run } = useSubmit(onClose);

  const defaults: TripValues = trip
    ? tripToValues(trip)
    : {
        startOdometer: currentOdometer !== undefined ? String(currentOdometer) : "",
        startedAt: nowLocalInput(),
        purpose: "",
        endOdometer: "",
        endedAt: "",
      };
  if (mode === "finish" && !defaults.endedAt) defaults.endedAt = nowLocalInput();

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<TripValues>({ resolver: zodResolver(tripSchema), defaultValues: defaults });

  const showStart = mode !== "finish";
  const showEnd = mode !== "start";
  // Ao encerrar, o fim deixa de ser opcional.
  const submit = handleSubmit((values) => {
    if (mode === "finish" && values.endOdometer.trim() === "") return;
    return run(() => save.mutateAsync({ vehicleId, id: trip?.id ?? null, values }));
  });

  return (
    <form className="flex flex-col gap-4" onSubmit={submit}>
      {showStart && (
        <>
          <FieldRow>
            <Field label="Início" error={errors.startedAt?.message}>
              <Input type="datetime-local" max={nowLocalInput()} {...register("startedAt")} />
            </Field>
            <Field label="Quilometragem inicial (km)" error={errors.startOdometer?.message}>
              <Input inputMode="numeric" autoFocus {...register("startOdometer")} />
            </Field>
          </FieldRow>
          <Field label="Motivo (opcional)" error={errors.purpose?.message}>
            <Input placeholder="Ex.: Viagem a Campinas" maxLength={160} {...register("purpose")} />
          </Field>
        </>
      )}
      {showEnd && (
        <FieldRow>
          <Field
            label={mode === "finish" ? "Chegada" : "Fim (opcional)"}
            error={errors.endedAt?.message}
          >
            <Input type="datetime-local" max={nowLocalInput()} {...register("endedAt")} />
          </Field>
          <Field
            label={mode === "finish" ? "Quilometragem final (km)" : "Quilometragem final (opcional)"}
            error={errors.endOdometer?.message}
          >
            <Input inputMode="numeric" autoFocus={mode === "finish"} {...register("endOdometer")} />
          </Field>
        </FieldRow>
      )}
      <FormFooter
        pending={pending}
        error={error}
        submitLabel={mode === "start" ? "Iniciar viagem" : mode === "finish" ? "Encerrar viagem" : "Salvar alterações"}
        onCancel={onClose}
      />
    </form>
  );
}
