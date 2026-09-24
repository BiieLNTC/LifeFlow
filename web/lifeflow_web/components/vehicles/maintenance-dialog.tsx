"use client";

import { Controller, useFieldArray, useForm, useWatch } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Plus, Trash2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Field, OptionSelect, Segmented } from "@/components/finance/shared";
import { FormDialog, FormFooter, useSubmit } from "@/components/finance/form-dialog";
import { FieldRow, NotesField } from "@/components/vehicles/shared";
import { formatCurrency, moneyToInput, parseMoney, todayIso } from "@/lib/finance/format";
import { useSaveMaintenance } from "@/lib/vehicles/hooks";
import {
  maintenanceSchema,
  type MaintenanceItemValues,
  type MaintenanceValues,
} from "@/lib/vehicles/schemas";
import {
  maintenanceCategoryOptions,
  maintenanceTypeOptions,
  type MaintenanceType,
} from "@/lib/vehicles/options";
import type { Maintenance } from "@/lib/vehicles/api";

const blankItem = (): MaintenanceItemValues => ({
  category: "",
  description: "",
  partAmount: "",
  laborAmount: "",
  nextOdometer: "",
  nextDate: "",
});

export function MaintenanceDialog({
  vehicleId,
  open,
  onOpenChange,
  initial,
  defaultOdometer,
  onSaved,
}: {
  vehicleId: string;
  open: boolean;
  onOpenChange: (open: boolean) => void;
  initial?: Maintenance | null;
  defaultOdometer?: number;
  /** Chamado após salvar; a tela usa para oferecer a criação de lembretes. */
  onSaved?: (maintenanceId: string, values: MaintenanceValues, isNew: boolean) => void;
}) {
  return (
    <FormDialog
      open={open}
      onOpenChange={onOpenChange}
      title={initial ? "Editar manutenção" : "Nova manutenção"}
      description="Cada serviço ou peça é um item; o total é a soma de peças e mão de obra."
      className="sm:max-w-2xl"
    >
      <MaintenanceForm
        vehicleId={vehicleId}
        initial={initial}
        defaultOdometer={defaultOdometer}
        onSaved={onSaved}
        onClose={() => onOpenChange(false)}
      />
    </FormDialog>
  );
}

function MaintenanceForm({
  vehicleId,
  initial,
  defaultOdometer,
  onSaved,
  onClose,
}: {
  vehicleId: string;
  initial?: Maintenance | null;
  defaultOdometer?: number;
  onSaved?: (maintenanceId: string, values: MaintenanceValues, isNew: boolean) => void;
  onClose: () => void;
}) {
  const save = useSaveMaintenance();
  const { pending, error, run } = useSubmit(onClose);
  const {
    register,
    control,
    handleSubmit,
    formState: { errors },
  } = useForm<MaintenanceValues>({
    resolver: zodResolver(maintenanceSchema),
    defaultValues: {
      date: initial?.maintenance_date ?? todayIso(),
      odometer: initial ? String(initial.odometer) : defaultOdometer ? String(defaultOdometer) : "",
      type: (initial?.maintenance_type as MaintenanceType | undefined) ?? "preventive",
      workshop: initial?.workshop ?? "",
      notes: initial?.notes ?? "",
      items: initial?.maintenance_items.length
        ? initial.maintenance_items.map((i) => ({
            category: i.category,
            description: i.description,
            partAmount: i.part_amount ? moneyToInput(i.part_amount) : "",
            laborAmount: i.labor_amount ? moneyToInput(i.labor_amount) : "",
            nextOdometer: i.next_replacement_odometer != null ? String(i.next_replacement_odometer) : "",
            nextDate: i.next_replacement_date ?? "",
          }))
        : [blankItem()],
    },
  });
  const { fields, append, remove } = useFieldArray({ control, name: "items" });
  const items = useWatch({ control, name: "items" });
  const total = items.reduce(
    (sum, i) => sum + (parseMoney(i.partAmount) ?? 0) + (parseMoney(i.laborAmount) ?? 0),
    0,
  );

  return (
    <form
      className="flex max-h-[70vh] flex-col gap-4 overflow-y-auto px-0.5"
      onSubmit={handleSubmit((values) =>
        run(async () => {
          const id = await save.mutateAsync({ vehicleId, id: initial?.id ?? null, values });
          onSaved?.(id, values, !initial);
        }),
      )}
    >
      <Controller
        control={control}
        name="type"
        render={({ field }) => (
          <Segmented
            value={field.value as MaintenanceType}
            onChange={field.onChange}
            options={maintenanceTypeOptions.map((o) => ({
              value: o.value as MaintenanceType,
              label: o.label,
            }))}
          />
        )}
      />
      <FieldRow>
        <Field label="Data" error={errors.date?.message}>
          <Input type="date" max={todayIso()} {...register("date")} />
        </Field>
        <Field label="Quilometragem (km)" error={errors.odometer?.message}>
          <Input inputMode="numeric" {...register("odometer")} />
        </Field>
      </FieldRow>
      <Field label="Oficina (opcional)" error={errors.workshop?.message}>
        <Input maxLength={120} {...register("workshop")} />
      </Field>

      <div className="flex flex-col gap-3">
        <div className="flex items-center justify-between">
          <span className="text-xs font-semibold tracking-widest text-muted-foreground uppercase">
            Itens
          </span>
          <span className="text-sm font-medium tabular-nums">Total {formatCurrency(total)}</span>
        </div>
        {fields.map((field, index) => {
          const itemErrors = errors.items?.[index];
          return (
            <fieldset key={field.id} className="flex flex-col gap-3 rounded-xl border p-3">
              <div className="grid gap-3 sm:grid-cols-[minmax(0,1fr)_minmax(0,1.4fr)_auto] sm:items-start">
                <Field label="Categoria" error={itemErrors?.category?.message}>
                  <Controller
                    control={control}
                    name={`items.${index}.category`}
                    render={({ field: f }) => (
                      <OptionSelect
                        value={f.value}
                        onChange={f.onChange}
                        options={maintenanceCategoryOptions}
                        invalid={Boolean(itemErrors?.category)}
                      />
                    )}
                  />
                </Field>
                <Field label="Descrição" error={itemErrors?.description?.message}>
                  <Input maxLength={160} {...register(`items.${index}.description`)} />
                </Field>
                {fields.length > 1 && (
                  <Button
                    type="button"
                    variant="ghost"
                    size="icon-sm"
                    className="sm:mt-6"
                    aria-label={`Remover item ${index + 1}`}
                    onClick={() => remove(index)}
                  >
                    <Trash2 />
                  </Button>
                )}
              </div>
              <div className="grid gap-3 sm:grid-cols-2">
                <Field label="Peças (R$)" error={itemErrors?.partAmount?.message}>
                  <Input inputMode="decimal" placeholder="0,00" {...register(`items.${index}.partAmount`)} />
                </Field>
                <Field label="Mão de obra (R$)" error={itemErrors?.laborAmount?.message}>
                  <Input inputMode="decimal" placeholder="0,00" {...register(`items.${index}.laborAmount`)} />
                </Field>
                <Field label="Próxima troca em (km)" error={itemErrors?.nextOdometer?.message}>
                  <Input inputMode="numeric" {...register(`items.${index}.nextOdometer`)} />
                </Field>
                <Field label="Próxima troca em (data)" error={itemErrors?.nextDate?.message}>
                  <Input type="date" {...register(`items.${index}.nextDate`)} />
                </Field>
              </div>
            </fieldset>
          );
        })}
        {typeof errors.items?.message === "string" && (
          <p className="text-xs text-critical">{errors.items.message}</p>
        )}
        <Button type="button" variant="outline" onClick={() => append(blankItem())}>
          <Plus /> Adicionar item
        </Button>
      </div>

      <Field label="Observações (opcional)" error={errors.notes?.message}>
        <NotesField {...register("notes")} />
      </Field>
      <FormFooter
        pending={pending}
        error={error}
        submitLabel={initial ? "Salvar alterações" : "Salvar manutenção"}
        onCancel={onClose}
      />
    </form>
  );
}
