import { z } from "zod";
import { parseMoney, todayIso } from "@/lib/finance/format";
import {
  normalizePlate,
  parseDecimal,
  parseInteger,
  plateRegex,
  refuelingTotalMatches,
} from "@/lib/vehicles/format";

const isoDate = z.string().regex(/^\d{4}-\d{2}-\d{2}$/, "Informe a data.");
const pastDate = isoDate.refine((v) => v <= todayIso(), "A data não pode ser futura.");

const positiveMoney = z.string().refine((v) => {
  const n = parseMoney(v);
  return n !== null && n > 0;
}, "Informe um valor válido.");

/** Campo opcional: vazio vale 0; preenchido precisa ser um valor válido. */
const optionalMoney = z
  .string()
  .refine((v) => v.trim() === "" || parseMoney(v) !== null, "Informe um valor válido.");

const odometer = z.string().refine((v) => parseInteger(v) !== null, "Informe a quilometragem.");
const optionalOdometer = z
  .string()
  .refine((v) => v.trim() === "" || parseInteger(v) !== null, "Quilometragem inválida.");

const optionalDate = z
  .string()
  .refine((v) => v === "" || /^\d{4}-\d{2}-\d{2}$/.test(v), "Data inválida.");

const notes = z.string().max(2000, "No máximo 2000 caracteres.");

function isYear(v: string, max: number) {
  const n = Number(v);
  return Number.isInteger(n) && n >= 1886 && n <= max;
}

export const vehicleSchema = z
  .object({
    type: z.enum(["car", "motorcycle"]),
    nickname: z.string().trim().min(1, "Informe o apelido.").max(80),
    brand: z.string().trim().min(1, "Informe a marca.").max(80),
    model: z.string().trim().min(1, "Informe o modelo.").max(80),
    version: z.string().trim().max(100),
    manufactureYear: z.string(),
    modelYear: z.string(),
    licensePlate: z.string(),
    fuelType: z.string(), // "" = não informado
    currentOdometer: odometer,
    purchaseDate: optionalDate,
    purchasePrice: optionalMoney,
    notes,
  })
  .superRefine((v, ctx) => {
    const issue = (path: string, message: string) =>
      ctx.addIssue({ code: "custom", path: [path], message });

    if (v.manufactureYear && !isYear(v.manufactureYear, 2100)) {
      issue("manufactureYear", "Ano inválido.");
    }
    if (v.modelYear && !isYear(v.modelYear, 2101)) {
      issue("modelYear", "Ano inválido.");
    } else if (v.modelYear && v.manufactureYear && isYear(v.manufactureYear, 2100)) {
      const m = Number(v.manufactureYear);
      const y = Number(v.modelYear);
      if (y < m || y > m + 1) issue("modelYear", "Deve ser o ano de fabricação ou o seguinte.");
    }
    if (v.licensePlate.trim() && !plateRegex.test(normalizePlate(v.licensePlate))) {
      issue("licensePlate", "Use o formato ABC1D23 ou ABC1234.");
    }
    if (v.purchaseDate && v.purchaseDate > todayIso()) {
      issue("purchaseDate", "A data da compra não pode ser futura.");
    }
  });
export type VehicleValues = z.infer<typeof vehicleSchema>;

const maintenanceItemSchema = z.object({
  category: z.string().min(1, "Selecione a categoria."),
  description: z.string().trim().min(1, "Informe a descrição.").max(160),
  partAmount: optionalMoney,
  laborAmount: optionalMoney,
  nextOdometer: optionalOdometer,
  nextDate: optionalDate,
});
export type MaintenanceItemValues = z.infer<typeof maintenanceItemSchema>;

export const maintenanceSchema = z
  .object({
    date: pastDate,
    odometer,
    type: z.enum(["preventive", "corrective"]),
    workshop: z.string().trim().max(120),
    notes,
    items: z.array(maintenanceItemSchema).min(1, "Adicione pelo menos um item."),
  })
  .superRefine((v, ctx) => {
    const km = parseInteger(v.odometer);
    v.items.forEach((item, i) => {
      const next = parseInteger(item.nextOdometer);
      if (km !== null && next !== null && next <= km) {
        ctx.addIssue({
          code: "custom",
          path: ["items", i, "nextOdometer"],
          message: "Deve ser maior que a quilometragem atual.",
        });
      }
      if (item.nextDate && /^\d{4}-\d{2}-\d{2}$/.test(v.date) && item.nextDate <= v.date) {
        ctx.addIssue({
          code: "custom",
          path: ["items", i, "nextDate"],
          message: "Deve ser depois da data da manutenção.",
        });
      }
    });
  });
export type MaintenanceValues = z.infer<typeof maintenanceSchema>;

export const refuelingSchema = z
  .object({
    date: pastDate,
    odometer,
    fuelType: z.string().min(1, "Selecione o combustível."),
    liters: z.string().refine((v) => (parseDecimal(v) ?? 0) > 0, "Informe os litros."),
    unitPrice: z.string().refine((v) => (parseDecimal(v) ?? 0) > 0, "Informe o preço por litro."),
    total: positiveMoney,
    fullTank: z.boolean(),
    gasStation: z.string().trim().max(120),
    notes,
  })
  .superRefine((v, ctx) => {
    const liters = parseDecimal(v.liters);
    const price = parseDecimal(v.unitPrice);
    const total = parseMoney(v.total);
    if (liters && price && total && !refuelingTotalMatches(liters, price, total)) {
      ctx.addIssue({
        code: "custom",
        path: ["total"],
        message: "O total não confere com litros × preço.",
      });
    }
  });
export type RefuelingValues = z.infer<typeof refuelingSchema>;

export const expenseSchema = z.object({
  date: pastDate,
  category: z.string().min(1, "Selecione a categoria."),
  description: z.string().trim().min(1, "Informe a descrição.").max(160),
  amount: positiveMoney,
  notes,
});
export type ExpenseValues = z.infer<typeof expenseSchema>;

export const reminderSchema = z
  .object({
    description: z.string().trim().min(1, "Informe a descrição.").max(160),
    targetOdometer: optionalOdometer,
    targetDate: optionalDate,
  })
  .refine((v) => v.targetOdometer.trim() !== "" || v.targetDate !== "", {
    path: ["targetOdometer"],
    message: "Informe a quilometragem ou a data.",
  });
export type ReminderValues = z.infer<typeof reminderSchema>;

export const documentSchema = z
  .object({
    type: z.enum(["insurance", "licensing", "inspection", "other"]),
    description: z.string().trim().min(1, "Informe a descrição.").max(160),
    issueDate: z
      .string()
      .refine((v) => v === "" || (/^\d{4}-\d{2}-\d{2}$/.test(v) && v <= todayIso()), "Data inválida."),
    expiryDate: optionalDate,
  })
  .refine((v) => !v.issueDate || !v.expiryDate || v.expiryDate >= v.issueDate, {
    path: ["expiryDate"],
    message: "O vencimento não pode ser antes da emissão.",
  });
export type DocumentValues = z.infer<typeof documentSchema>;

export const tripSchema = z
  .object({
    startOdometer: odometer,
    startedAt: z.string().min(1, "Informe o início."),
    purpose: z.string().trim().max(160),
    endOdometer: optionalOdometer,
    endedAt: z.string(),
  })
  .superRefine((v, ctx) => {
    const hasEnd = v.endOdometer.trim() !== "";
    const hasEndTime = v.endedAt !== "";
    if (hasEnd !== hasEndTime) {
      ctx.addIssue({
        code: "custom",
        path: [hasEnd ? "endedAt" : "endOdometer"],
        message: "Informe quilometragem e horário do fim juntos.",
      });
      return;
    }
    if (!hasEnd) return;
    const start = parseInteger(v.startOdometer);
    const end = parseInteger(v.endOdometer);
    if (start !== null && end !== null && end < start) {
      ctx.addIssue({
        code: "custom",
        path: ["endOdometer"],
        message: "Não pode ser menor que a quilometragem inicial.",
      });
    }
    if (v.startedAt && v.endedAt < v.startedAt) {
      ctx.addIssue({
        code: "custom",
        path: ["endedAt"],
        message: "O fim não pode ser antes do início.",
      });
    }
    if (new Date(v.endedAt).getTime() > Date.now() + 60_000) {
      ctx.addIssue({ code: "custom", path: ["endedAt"], message: "O fim não pode ser futuro." });
    }
  });
export type TripValues = z.infer<typeof tripSchema>;
