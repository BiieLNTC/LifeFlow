"use client";

import { Controller, useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Field, OptionSelect } from "@/components/finance/shared";
import { FormDialog, FormFooter, useSubmit } from "@/components/finance/form-dialog";
import { FieldRow, NotesField } from "@/components/vehicles/shared";
import { moneyToInput, todayIso } from "@/lib/finance/format";
import { decimalToInput, recalcRefueling, type RefuelingSource } from "@/lib/vehicles/format";
import { useSaveRefueling } from "@/lib/vehicles/hooks";
import { refuelingSchema, type RefuelingValues } from "@/lib/vehicles/schemas";
import { fuelTypeOptions } from "@/lib/vehicles/options";
import type { Refueling } from "@/lib/vehicles/api";

type Props = {
  vehicleId: string;
  open: boolean;
  onOpenChange: (open: boolean) => void;
  initial?: Refueling | null;
  /** Odômetro e combustível do veículo, para pré-preencher um novo abastecimento. */
  defaultOdometer?: number;
  defaultFuelType?: string | null;
};

export function RefuelingDialog({ open, onOpenChange, ...form }: Props) {
  return (
    <FormDialog
      open={open}
      onOpenChange={onOpenChange}
      title={form.initial ? "Editar abastecimento" : "Novo abastecimento"}
      description="Preencha dois entre litros, preço e total — o terceiro é calculado."
    >
      <RefuelingForm {...form} onClose={() => onOpenChange(false)} />
    </FormDialog>
  );
}

function RefuelingForm({
  vehicleId,
  initial,
  defaultOdometer,
  defaultFuelType,
  onClose,
}: Omit<Props, "open" | "onOpenChange"> & { onClose: () => void }) {
  const save = useSaveRefueling();
  const { pending, error, run } = useSubmit(onClose);
  const {
    register,
    control,
    handleSubmit,
    getValues,
    setValue,
    formState: { errors },
  } = useForm<RefuelingValues>({
    resolver: zodResolver(refuelingSchema),
    defaultValues: {
      date: initial?.refueling_date ?? todayIso(),
      odometer: initial ? String(initial.odometer) : defaultOdometer ? String(defaultOdometer) : "",
      fuelType:
        initial?.fuel_type ?? (defaultFuelType && defaultFuelType !== "flex" ? defaultFuelType : ""),
      liters: initial ? decimalToInput(initial.liters, 3) : "",
      unitPrice: initial ? decimalToInput(initial.unit_price, 4) : "",
      total: initial ? moneyToInput(initial.total_amount) : "",
      fullTank: initial?.full_tank ?? false,
      gasStation: initial?.gas_station ?? "",
      notes: initial?.notes ?? "",
    },
  });

  // Litros × preço = total: editar um campo recalcula o derivado (regra do mobile).
  function recalc(source: RefuelingSource) {
    const { liters, unitPrice, total } = getValues();
    const next = recalcRefueling(source, { liters, unitPrice, total });
    if (next.unitPrice !== undefined) setValue("unitPrice", next.unitPrice, { shouldValidate: true });
    if (next.total !== undefined) setValue("total", next.total, { shouldValidate: true });
  }

  return (
    <form
      className="flex flex-col gap-4"
      onSubmit={handleSubmit((values) =>
        run(() => save.mutateAsync({ vehicleId, id: initial?.id ?? null, values })),
      )}
    >
      <FieldRow>
        <Field label="Data" error={errors.date?.message}>
          <Input type="date" max={todayIso()} {...register("date")} />
        </Field>
        <Field label="Quilometragem (km)" error={errors.odometer?.message}>
          <Input inputMode="numeric" autoFocus {...register("odometer")} />
        </Field>
      </FieldRow>
      <Field label="Combustível" error={errors.fuelType?.message}>
        <Controller
          control={control}
          name="fuelType"
          render={({ field }) => (
            <OptionSelect
              value={field.value}
              onChange={field.onChange}
              options={fuelTypeOptions}
              invalid={Boolean(errors.fuelType)}
            />
          )}
        />
      </Field>
      <div className="grid gap-3 sm:grid-cols-3">
        <Field label="Litros" error={errors.liters?.message}>
          <Input
            inputMode="decimal"
            placeholder="0,000"
            {...register("liters", { onChange: () => recalc("liters") })}
          />
        </Field>
        <Field label="Preço por litro" error={errors.unitPrice?.message}>
          <Input
            inputMode="decimal"
            placeholder="0,0000"
            {...register("unitPrice", { onChange: () => recalc("unitPrice") })}
          />
        </Field>
        <Field label="Total" error={errors.total?.message}>
          <Input
            inputMode="decimal"
            placeholder="0,00"
            {...register("total", { onChange: () => recalc("total") })}
          />
        </Field>
      </div>
      <Controller
        control={control}
        name="fullTank"
        render={({ field }) => (
          <div className="flex items-center justify-between gap-3 rounded-lg border p-3">
            <div>
              <Label htmlFor="full-tank">Tanque cheio</Label>
              <p className="text-xs text-muted-foreground">
                Necessário para calcular o consumo (km/l).
              </p>
            </div>
            <Switch id="full-tank" checked={field.value} onCheckedChange={field.onChange} />
          </div>
        )}
      />
      <Field label="Posto (opcional)" error={errors.gasStation?.message}>
        <Input maxLength={120} {...register("gasStation")} />
      </Field>
      <Field label="Observações (opcional)" error={errors.notes?.message}>
        <NotesField {...register("notes")} />
      </Field>
      <FormFooter
        pending={pending}
        error={error}
        submitLabel={initial ? "Salvar alterações" : "Salvar abastecimento"}
        onCancel={onClose}
      />
    </form>
  );
}
