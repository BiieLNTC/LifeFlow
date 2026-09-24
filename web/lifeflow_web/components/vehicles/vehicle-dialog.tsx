"use client";

import { Controller, useForm, useWatch } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Input } from "@/components/ui/input";
import { Field, OptionSelect, Segmented } from "@/components/finance/shared";
import { FormDialog, FormFooter, useSubmit } from "@/components/finance/form-dialog";
import { FieldRow, NotesField } from "@/components/vehicles/shared";
import { moneyToInput, todayIso } from "@/lib/finance/format";
import {
  useCatalogBrands,
  useCatalogModels,
  useSaveVehicle,
} from "@/lib/vehicles/hooks";
import { vehicleSchema, type VehicleValues } from "@/lib/vehicles/schemas";
import { fuelTypeOptions, vehicleTypeOptions, type VehicleType } from "@/lib/vehicles/options";
import { formatPlate } from "@/lib/vehicles/format";
import type { Vehicle } from "@/lib/vehicles/api";

export function VehicleDialog({
  open,
  onOpenChange,
  initial,
  onSaved,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  initial?: Vehicle | null;
  onSaved?: (vehicle: Vehicle) => void;
}) {
  return (
    <FormDialog
      open={open}
      onOpenChange={onOpenChange}
      title={initial ? "Editar veículo" : "Novo veículo"}
      className="sm:max-w-xl"
    >
      <VehicleForm initial={initial} onSaved={onSaved} onClose={() => onOpenChange(false)} />
    </FormDialog>
  );
}

function VehicleForm({
  initial,
  onSaved,
  onClose,
}: {
  initial?: Vehicle | null;
  onSaved?: (vehicle: Vehicle) => void;
  onClose: () => void;
}) {
  const save = useSaveVehicle();
  const { pending, error, run } = useSubmit(onClose);
  const {
    register,
    control,
    handleSubmit,
    formState: { errors },
  } = useForm<VehicleValues>({
    resolver: zodResolver(vehicleSchema),
    defaultValues: {
      type: (initial?.vehicle_type as VehicleType | undefined) ?? "car",
      nickname: initial?.nickname ?? "",
      brand: initial?.brand ?? "",
      model: initial?.model ?? "",
      version: initial?.version ?? "",
      manufactureYear: initial?.manufacture_year?.toString() ?? "",
      modelYear: initial?.model_year?.toString() ?? "",
      licensePlate: initial?.license_plate ? formatPlate(initial.license_plate) : "",
      fuelType: initial?.fuel_type ?? "",
      currentOdometer: initial ? String(initial.current_odometer) : "0",
      purchaseDate: initial?.purchase_date ?? "",
      purchasePrice: initial?.purchase_price != null ? moneyToInput(initial.purchase_price) : "",
      notes: initial?.notes ?? "",
    },
  });

  // Catálogo FIPE: só sugere (datalist); se falhar, os campos seguem livres.
  const type = useWatch({ control, name: "type" });
  const brand = useWatch({ control, name: "brand" });
  const brands = useCatalogBrands(type);
  const brandCode = brands.data?.find(
    (b) => b.name.toLowerCase() === brand.trim().toLowerCase(),
  )?.code;
  const models = useCatalogModels(type, brandCode);

  return (
    <form
      className="flex max-h-[70vh] flex-col gap-4 overflow-y-auto px-0.5"
      onSubmit={handleSubmit((values) =>
        run(async () => {
          const saved = await save.mutateAsync({ id: initial?.id ?? null, values });
          onSaved?.(saved);
        }),
      )}
    >
      <Controller
        control={control}
        name="type"
        render={({ field }) => (
          <Segmented
            value={field.value as VehicleType}
            onChange={field.onChange}
            options={vehicleTypeOptions.map((o) => ({ value: o.value as VehicleType, label: o.label }))}
          />
        )}
      />
      <Field label="Apelido" error={errors.nickname?.message}>
        <Input placeholder="Ex.: Meu Gol" maxLength={80} autoFocus {...register("nickname")} />
      </Field>
      <FieldRow>
        <Field label="Marca" error={errors.brand?.message}>
          <Input list="catalog-brands" maxLength={80} autoComplete="off" {...register("brand")} />
          <datalist id="catalog-brands">
            {brands.data?.map((b) => <option key={b.code} value={b.name} />)}
          </datalist>
        </Field>
        <Field label="Modelo" error={errors.model?.message}>
          <Input list="catalog-models" maxLength={80} autoComplete="off" {...register("model")} />
          <datalist id="catalog-models">
            {models.data?.map((m) => <option key={m.code} value={m.name} />)}
          </datalist>
        </Field>
      </FieldRow>
      <Field label="Versão (opcional)" error={errors.version?.message}>
        <Input maxLength={100} {...register("version")} />
      </Field>
      <FieldRow>
        <Field label="Ano de fabricação" error={errors.manufactureYear?.message}>
          <Input inputMode="numeric" maxLength={4} placeholder="2020" {...register("manufactureYear")} />
        </Field>
        <Field label="Ano do modelo" error={errors.modelYear?.message}>
          <Input inputMode="numeric" maxLength={4} placeholder="2021" {...register("modelYear")} />
        </Field>
      </FieldRow>
      <FieldRow>
        <Field label="Placa (opcional)" error={errors.licensePlate?.message}>
          <Input placeholder="ABC1D23" maxLength={8} className="uppercase" {...register("licensePlate")} />
        </Field>
        <Field label="Combustível (opcional)" error={errors.fuelType?.message}>
          <Controller
            control={control}
            name="fuelType"
            render={({ field }) => (
              <OptionSelect
                value={field.value}
                onChange={field.onChange}
                options={fuelTypeOptions}
                emptyLabel="Não informado"
              />
            )}
          />
        </Field>
      </FieldRow>
      <Field label="Quilometragem atual (km)" error={errors.currentOdometer?.message}>
        <Input inputMode="numeric" {...register("currentOdometer")} />
      </Field>
      <FieldRow>
        <Field label="Data da compra (opcional)" error={errors.purchaseDate?.message}>
          <Input type="date" max={todayIso()} {...register("purchaseDate")} />
        </Field>
        <Field label="Valor da compra (opcional)" error={errors.purchasePrice?.message}>
          <Input inputMode="decimal" placeholder="0,00" {...register("purchasePrice")} />
        </Field>
      </FieldRow>
      <Field label="Observações (opcional)" error={errors.notes?.message}>
        <NotesField {...register("notes")} />
      </Field>
      <FormFooter
        pending={pending}
        error={error}
        submitLabel={initial ? "Salvar alterações" : "Salvar veículo"}
        onCancel={onClose}
      />
    </form>
  );
}
