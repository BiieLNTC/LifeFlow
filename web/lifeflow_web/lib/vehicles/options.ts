import type { Option } from "@/components/finance/shared";

function options<T extends Record<string, string>>(labels: T): Option[] {
  return Object.entries(labels).map(([value, label]) => ({ value, label }));
}

export const vehicleTypeLabels = { car: "Carro", motorcycle: "Moto" } as const;
export type VehicleType = keyof typeof vehicleTypeLabels;
export const vehicleTypeOptions = options(vehicleTypeLabels);

export const fuelTypeLabels = {
  gasoline: "Gasolina",
  ethanol: "Etanol",
  flex: "Flex",
  diesel: "Diesel",
  electric: "Elétrico",
  hybrid: "Híbrido",
  other: "Outro",
} as const;
export type FuelType = keyof typeof fuelTypeLabels;
export const fuelTypeOptions = options(fuelTypeLabels);

export const maintenanceTypeLabels = {
  preventive: "Preventiva",
  corrective: "Corretiva",
} as const;
export type MaintenanceType = keyof typeof maintenanceTypeLabels;
export const maintenanceTypeOptions = options(maintenanceTypeLabels);

export const maintenanceCategoryLabels = {
  oil: "Óleo",
  oil_filter: "Filtro de óleo",
  air_filter: "Filtro de ar",
  fuel_filter: "Filtro de combustível",
  brakes: "Freios",
  tires: "Pneus",
  suspension: "Suspensão",
  belts: "Correias",
  battery: "Bateria",
  air_conditioning: "Ar-condicionado",
  alignment: "Alinhamento",
  balancing: "Balanceamento",
  other: "Outros",
} as const;
export type MaintenanceCategory = keyof typeof maintenanceCategoryLabels;
export const maintenanceCategoryOptions = options(maintenanceCategoryLabels);

export const expenseCategoryLabels = {
  fuel: "Combustível",
  maintenance: "Manutenção",
  insurance: "Seguro",
  ipva: "IPVA",
  licensing: "Licenciamento",
  fine: "Multa",
  toll: "Pedágio",
  parking: "Estacionamento",
  car_wash: "Lavagem",
  accessories: "Acessórios",
  tires: "Pneus",
  other: "Outros",
} as const;
export type ExpenseCategory = keyof typeof expenseCategoryLabels;
export const expenseCategoryOptions = options(expenseCategoryLabels);

export const documentTypeLabels = {
  insurance: "Seguro",
  licensing: "Licenciamento",
  inspection: "Vistoria",
  other: "Outro",
} as const;
export type DocumentType = keyof typeof documentTypeLabels;
export const documentTypeOptions = options(documentTypeLabels);

export const timelineTypeLabels = {
  maintenance: "Manutenção",
  refueling: "Abastecimento",
  expense: "Despesa",
} as const;
export type TimelineType = keyof typeof timelineTypeLabels;

/** Rótulo da `category` de um evento da timeline, conforme o tipo do evento. */
export function timelineCategoryLabel(type: string, category: string | null): string | null {
  if (!category) return null;
  const map: Record<string, Record<string, string>> = {
    maintenance: maintenanceTypeLabels,
    refueling: fuelTypeLabels,
    expense: expenseCategoryLabels,
  };
  return map[type]?.[category] ?? null;
}

export type Urgency = "overdue" | "near" | "upcoming" | "completed";
export const urgencyLabels: Record<Urgency, string> = {
  overdue: "Vencido",
  near: "Próximo",
  upcoming: "Em dia",
  completed: "Concluído",
};

/** Tipos de arquivo aceitos como anexo (mesmos do bucket `vehicle-attachments`). */
export const attachmentTypes = ["image/jpeg", "image/png", "application/pdf"] as const;
export const attachmentMaxBytes = 10 * 1024 * 1024;
