import type { PostgrestError, SupabaseClient } from "@supabase/supabase-js";
import type { Database } from "@/lib/supabase/database.types";
import { parseMoney } from "@/lib/finance/format";
import {
  isoToLocalInput,
  localInputToIso,
  normalizePlate,
  parseDecimal,
  parseInteger,
} from "@/lib/vehicles/format";
import { attachmentMaxBytes, attachmentTypes } from "@/lib/vehicles/options";
import type {
  DocumentValues,
  ExpenseValues,
  MaintenanceValues,
  RefuelingValues,
  ReminderValues,
  TripValues,
  VehicleValues,
} from "@/lib/vehicles/schemas";

type Db = SupabaseClient<Database>;
type Tables = Database["public"]["Tables"];
type Views = Database["public"]["Views"];

export type Vehicle = Tables["vehicles"]["Row"];
export type MaintenanceItem = Tables["maintenance_items"]["Row"];
export type Maintenance = Tables["maintenances"]["Row"] & {
  maintenance_items: MaintenanceItem[];
};
export type Expense = Tables["expenses"]["Row"];
export type VehicleDocument = Tables["vehicle_documents"]["Row"];
export type Trip = Tables["trips"]["Row"];
export type Attachment = Tables["attachments"]["Row"];

// As views saem do gerador com todas as colunas nullable; as chaves e os campos
// abaixo são garantidos pela definição das views.
export type Refueling = Tables["refuelings"]["Row"] & { consumption_km_l: number | null };
export type Reminder = Tables["reminders"]["Row"] & {
  current_odometer: number;
  remaining_km: number | null;
  remaining_days: number | null;
  visual_status: "overdue" | "near" | "upcoming" | "completed";
};
export type TimelineEntry = {
  event_id: string;
  event_type: "maintenance" | "refueling" | "expense";
  vehicle_id: string;
  occurred_on: string;
  title: string;
  secondary_text: string | null;
  category: string | null;
  odometer: number | null;
  amount: number;
};
export type VehicleDashboard = Omit<
  Views["vehicle_dashboard"]["Row"],
  "vehicle_id" | "nickname" | "brand" | "model" | "vehicle_type" | "current_odometer" | "attention_count" | "monthly_spending"
> & {
  vehicle_id: string;
  nickname: string;
  brand: string;
  model: string;
  vehicle_type: string;
  current_odometer: number;
  attention_count: number;
  monthly_spending: number;
};

/** Erro com mensagem já em pt-BR, pronta para exibir. */
export class VehicleError extends Error {}

const nowIso = () => new Date().toISOString();

type Messages = Partial<Record<string, string>> & { default: string };

async function run<T>(
  op: PromiseLike<{ data: T; error: PostgrestError | null }>,
  messages: Messages,
  /** Regras do banco levantadas como exceção livre (sem código próprio). */
  byText: [substring: string, message: string][] = [],
): Promise<NonNullable<T>> {
  let result;
  try {
    result = await op;
  } catch {
    throw new VehicleError("Não foi possível conectar ao serviço.");
  }
  if (result.error) {
    const { code, message } = result.error;
    const textual = byText.find(([s]) => message.includes(s));
    throw new VehicleError(textual?.[1] ?? ((code && messages[code]) || messages.default));
  }
  return result.data as NonNullable<T>;
}

const blankToNull = (v: string) => {
  const t = v.trim();
  return t === "" ? null : t;
};
const money = (v: string) => parseMoney(v) as number;
const optionalMoney = (v: string) => (v.trim() === "" ? 0 : money(v));
const optionalInt = (v: string) => (v.trim() === "" ? null : (parseInteger(v) as number));
const int = (v: string) => parseInteger(v) as number;

const ownershipErrors = {
  "42501": "Você não tem permissão para acessar este veículo.",
  PGRST116: "Registro não encontrado ou sem permissão de acesso.",
};

// ── Veículos ──────────────────────────────────────────────────────────────

const vehicleErrors: Messages = {
  ...ownershipErrors,
  "23505": "Já existe um veículo ativo com esta placa.",
  "23514": "Revise os dados informados e tente novamente.",
  default: "Não foi possível salvar o veículo. Tente novamente.",
};

export async function listVehicles(db: Db): Promise<Vehicle[]> {
  return run(
    db.from("vehicles").select("*").is("deleted_at", null).order("updated_at", { ascending: false }),
    vehicleErrors,
  );
}

export async function getVehicle(db: Db, id: string): Promise<Vehicle> {
  return run(
    db.from("vehicles").select("*").eq("id", id).is("deleted_at", null).single(),
    vehicleErrors,
  );
}

export async function listDashboards(db: Db): Promise<VehicleDashboard[]> {
  const rows = await run(db.from("vehicle_dashboard").select("*"), vehicleErrors);
  return rows as unknown as VehicleDashboard[];
}

export async function getDashboard(db: Db, vehicleId: string): Promise<VehicleDashboard> {
  const row = await run(
    db.from("vehicle_dashboard").select("*").eq("vehicle_id", vehicleId).single(),
    vehicleErrors,
  );
  return row as unknown as VehicleDashboard;
}

export async function saveVehicle(db: Db, id: string | null, v: VehicleValues): Promise<Vehicle> {
  const payload = {
    vehicle_type: v.type,
    nickname: v.nickname.trim(),
    brand: v.brand.trim(),
    model: v.model.trim(),
    version: blankToNull(v.version),
    manufacture_year: optionalInt(v.manufactureYear),
    model_year: optionalInt(v.modelYear),
    license_plate: blankToNull(normalizePlate(v.licensePlate)),
    fuel_type: blankToNull(v.fuelType),
    current_odometer: int(v.currentOdometer),
    purchase_date: blankToNull(v.purchaseDate),
    purchase_price: v.purchasePrice.trim() === "" ? null : money(v.purchasePrice),
    notes: blankToNull(v.notes),
    active: true,
  };
  return run(
    id
      ? db.from("vehicles").update(payload).eq("id", id).select().single()
      : db.from("vehicles").insert(payload).select().single(),
    vehicleErrors,
    [["future", "A data da compra não pode estar no futuro."]],
  );
}

export async function deleteVehicle(db: Db, id: string) {
  await run(
    db
      .from("vehicles")
      .update({ active: false, deleted_at: nowIso() })
      .eq("id", id)
      .select("id")
      .single(),
    vehicleErrors,
  );
}

// ── Manutenções ───────────────────────────────────────────────────────────

const maintenanceErrors: Messages = {
  ...ownershipErrors,
  "23514": "Revise os dados da manutenção e tente novamente.",
  "22001": "Revise os dados da manutenção e tente novamente.",
  "22P02": "Revise os dados da manutenção e tente novamente.",
  default: "Não foi possível salvar a manutenção. Tente novamente.",
};
const maintenanceTextErrors: [string, string][] = [
  ["future", "A data da manutenção não pode estar no futuro."],
  ["Odometer", "A quilometragem não combina com as datas do histórico."],
];

export async function listMaintenances(db: Db, vehicleId: string): Promise<Maintenance[]> {
  return run(
    db
      .from("maintenances")
      .select("*, maintenance_items(*)")
      .eq("vehicle_id", vehicleId)
      .is("deleted_at", null)
      .order("maintenance_date", { ascending: false })
      .order("created_at", { ascending: false }),
    maintenanceErrors,
  );
}

/** Cria ou atualiza a manutenção e seus itens atomicamente (RPC `save_maintenance`). */
export async function saveMaintenance(
  db: Db,
  vehicleId: string,
  id: string | null,
  v: MaintenanceValues,
): Promise<string> {
  const maintenanceId = id ?? crypto.randomUUID();
  await run(
    db.rpc("save_maintenance", {
      p_id: maintenanceId,
      p_vehicle_id: vehicleId,
      p_maintenance_date: v.date,
      p_odometer: int(v.odometer),
      p_maintenance_type: v.type,
      p_workshop: v.workshop.trim(),
      p_notes: v.notes.trim(),
      p_items: v.items.map((item) => ({
        id: crypto.randomUUID(),
        category: item.category,
        description: item.description.trim(),
        part_amount: optionalMoney(item.partAmount),
        labor_amount: optionalMoney(item.laborAmount),
        next_replacement_odometer: optionalInt(item.nextOdometer),
        next_replacement_date: blankToNull(item.nextDate),
      })),
    }),
    maintenanceErrors,
    maintenanceTextErrors,
  );
  return maintenanceId;
}

export async function deleteMaintenance(db: Db, id: string) {
  await run(
    db.from("maintenances").update({ deleted_at: nowIso() }).eq("id", id).select("id").single(),
    maintenanceErrors,
  );
}

// ── Abastecimentos ────────────────────────────────────────────────────────

const refuelingErrors: Messages = {
  ...ownershipErrors,
  "23514": "Revise os dados do abastecimento e tente novamente.",
  default: "Não foi possível salvar o abastecimento. Tente novamente.",
};

export async function listRefuelings(db: Db, vehicleId: string): Promise<Refueling[]> {
  const rows = await run(
    db
      .from("refueling_details")
      .select("*")
      .eq("vehicle_id", vehicleId)
      .order("refueling_date", { ascending: false })
      .order("created_at", { ascending: false }),
    refuelingErrors,
  );
  return rows as unknown as Refueling[];
}

export async function saveRefueling(
  db: Db,
  vehicleId: string,
  id: string | null,
  v: RefuelingValues,
) {
  const payload = {
    refueling_date: v.date,
    odometer: int(v.odometer),
    fuel_type: v.fuelType,
    liters: parseDecimal(v.liters) as number,
    unit_price: parseDecimal(v.unitPrice) as number,
    total_amount: money(v.total),
    full_tank: v.fullTank,
    gas_station: blankToNull(v.gasStation),
    notes: blankToNull(v.notes),
  };
  const textErrors: [string, string][] = [
    ["future", "A data do abastecimento não pode estar no futuro."],
    ["Odometer", "A quilometragem não combina com as datas do histórico."],
  ];
  await run(
    id
      ? db.from("refuelings").update(payload).eq("id", id).select("id").single()
      : db
          .from("refuelings")
          .insert({ ...payload, id: crypto.randomUUID(), vehicle_id: vehicleId })
          .select("id")
          .single(),
    refuelingErrors,
    textErrors,
  );
}

export async function deleteRefueling(db: Db, id: string) {
  await run(
    db.from("refuelings").update({ deleted_at: nowIso() }).eq("id", id).select("id").single(),
    refuelingErrors,
  );
}

// ── Despesas ──────────────────────────────────────────────────────────────

const expenseErrors: Messages = {
  ...ownershipErrors,
  "23514": "Revise os dados da despesa e tente novamente.",
  default: "Não foi possível salvar a despesa. Tente novamente.",
};

export async function listExpenses(db: Db, vehicleId: string): Promise<Expense[]> {
  return run(
    db
      .from("expenses")
      .select("*")
      .eq("vehicle_id", vehicleId)
      .is("deleted_at", null)
      .order("expense_date", { ascending: false })
      .order("created_at", { ascending: false }),
    expenseErrors,
  );
}

export async function saveExpense(db: Db, vehicleId: string, id: string | null, v: ExpenseValues) {
  const payload = {
    expense_date: v.date,
    category: v.category,
    description: v.description.trim(),
    amount: money(v.amount),
    notes: blankToNull(v.notes),
  };
  await run(
    id
      ? db.from("expenses").update(payload).eq("id", id).select("id").single()
      : db
          .from("expenses")
          .insert({ ...payload, id: crypto.randomUUID(), vehicle_id: vehicleId })
          .select("id")
          .single(),
    expenseErrors,
    [["future", "A data da despesa não pode estar no futuro."]],
  );
}

export async function deleteExpense(db: Db, id: string) {
  await run(
    db.from("expenses").update({ deleted_at: nowIso() }).eq("id", id).select("id").single(),
    expenseErrors,
  );
}

// ── Lembretes ─────────────────────────────────────────────────────────────

const reminderErrors: Messages = {
  "42501": "Você não tem permissão para este lembrete.",
  default: "Revise os dados do lembrete.",
};

export async function listReminders(db: Db, vehicleId: string): Promise<Reminder[]> {
  const rows = await run(
    db
      .from("reminder_details")
      .select("*")
      .eq("vehicle_id", vehicleId)
      .order("status")
      .order("target_date")
      .order("target_odometer"),
    reminderErrors,
  );
  return rows as unknown as Reminder[];
}

export async function saveReminder(
  db: Db,
  vehicleId: string,
  id: string | null,
  v: ReminderValues,
  originMaintenanceId: string | null = null,
) {
  const payload = {
    description: v.description.trim(),
    target_odometer: optionalInt(v.targetOdometer),
    target_date: blankToNull(v.targetDate),
  };
  await run(
    id
      ? db.from("reminders").update(payload).eq("id", id).select("id").single()
      : db
          .from("reminders")
          .insert({
            ...payload,
            id: crypto.randomUUID(),
            vehicle_id: vehicleId,
            origin_maintenance_id: originMaintenanceId,
          })
          .select("id")
          .single(),
    reminderErrors,
  );
}

export async function setReminderCompleted(db: Db, id: string, completed: boolean) {
  await run(
    db
      .from("reminders")
      .update({ status: completed ? "completed" : "active" })
      .eq("id", id)
      .select("id")
      .single(),
    reminderErrors,
  );
}

export async function deleteReminder(db: Db, id: string) {
  await run(
    db.from("reminders").update({ deleted_at: nowIso() }).eq("id", id).select("id").single(),
    reminderErrors,
  );
}

/** Lembretes sugeridos a partir dos itens de uma manutenção com próxima troca. */
export type ReminderSuggestion = {
  description: string;
  targetOdometer: string;
  targetDate: string;
};

export async function createRemindersFromMaintenance(
  db: Db,
  vehicleId: string,
  maintenanceId: string,
  suggestions: ReminderSuggestion[],
) {
  for (const s of suggestions) {
    await saveReminder(db, vehicleId, null, s, maintenanceId);
  }
}

// ── Documentos ────────────────────────────────────────────────────────────

const documentErrors: Messages = {
  ...ownershipErrors,
  "23514": "Revise as datas do documento.",
  default: "Não foi possível salvar o documento. Tente novamente.",
};

export async function listDocuments(db: Db, vehicleId: string): Promise<VehicleDocument[]> {
  return run(
    db
      .from("vehicle_documents")
      .select("*")
      .eq("vehicle_id", vehicleId)
      .is("deleted_at", null)
      .order("expiry_date", { ascending: true, nullsFirst: false }),
    documentErrors,
  );
}

export async function saveDocument(
  db: Db,
  vehicleId: string,
  id: string | null,
  v: DocumentValues,
) {
  const payload = {
    type: v.type,
    description: v.description.trim(),
    issue_date: blankToNull(v.issueDate),
    expiry_date: blankToNull(v.expiryDate),
  };
  await run(
    id
      ? db.from("vehicle_documents").update(payload).eq("id", id).select("id").single()
      : db
          .from("vehicle_documents")
          .insert({ ...payload, vehicle_id: vehicleId })
          .select("id")
          .single(),
    documentErrors,
  );
}

export async function deleteDocument(db: Db, id: string) {
  await run(
    db.from("vehicle_documents").update({ deleted_at: nowIso() }).eq("id", id).select("id").single(),
    documentErrors,
  );
}

// ── Diário de viagens ─────────────────────────────────────────────────────

const tripErrors: Messages = {
  ...ownershipErrors,
  "23514": "Revise a quilometragem e os horários da viagem.",
  default: "Não foi possível salvar a viagem. Tente novamente.",
};

export async function listTrips(db: Db, vehicleId: string): Promise<Trip[]> {
  return run(
    db
      .from("trips")
      .select("*")
      .eq("vehicle_id", vehicleId)
      .is("deleted_at", null)
      .order("started_at", { ascending: false }),
    tripErrors,
  );
}

export async function saveTrip(db: Db, vehicleId: string, id: string | null, v: TripValues) {
  const finished = v.endOdometer.trim() !== "";
  const payload = {
    start_odometer: int(v.startOdometer),
    started_at: localInputToIso(v.startedAt),
    purpose: blankToNull(v.purpose),
    end_odometer: finished ? int(v.endOdometer) : null,
    ended_at: finished ? localInputToIso(v.endedAt) : null,
  };
  await run(
    id
      ? db.from("trips").update(payload).eq("id", id).select("id").single()
      : db
          .from("trips")
          .insert({ ...payload, vehicle_id: vehicleId })
          .select("id")
          .single(),
    tripErrors,
    [
      ["future", "A data da viagem não pode estar no futuro."],
      ["Odometer", "A quilometragem não combina com as datas do histórico."],
    ],
  );
}

export async function deleteTrip(db: Db, id: string) {
  await run(
    db.from("trips").update({ deleted_at: nowIso() }).eq("id", id).select("id").single(),
    tripErrors,
  );
}

/** Valores do formulário a partir de uma viagem existente. */
export function tripToValues(t: Trip): TripValues {
  return {
    startOdometer: String(t.start_odometer),
    startedAt: isoToLocalInput(t.started_at),
    purpose: t.purpose ?? "",
    endOdometer: t.end_odometer === null ? "" : String(t.end_odometer),
    endedAt: t.ended_at ? isoToLocalInput(t.ended_at) : "",
  };
}

// ── Histórico (timeline) ──────────────────────────────────────────────────

export const TIMELINE_PAGE_SIZE = 30;

export async function listTimeline(
  db: Db,
  vehicleId: string,
  offset: number,
  limit = TIMELINE_PAGE_SIZE,
): Promise<TimelineEntry[]> {
  const rows = await run(
    db
      .from("vehicle_timeline")
      .select("*")
      .eq("vehicle_id", vehicleId)
      .order("occurred_on", { ascending: false })
      .order("created_at", { ascending: false })
      .order("event_type")
      .order("event_id")
      .range(offset, offset + limit - 1),
    { "42501": "Você não tem permissão para acessar este histórico.", default: "Não foi possível carregar o histórico." },
  );
  return rows as unknown as TimelineEntry[];
}

// ── Anexos de manutenção (Storage) ────────────────────────────────────────

const BUCKET = "vehicle-attachments";

const attachmentErrors: Messages = {
  "42501": "Você não tem permissão para este anexo.",
  default: "Não foi possível salvar os dados do anexo.",
};

export async function listAttachments(db: Db, maintenanceId: string): Promise<Attachment[]> {
  return run(
    db
      .from("attachments")
      .select("*")
      .eq("entity_type", "maintenance")
      .eq("entity_id", maintenanceId)
      .is("deleted_at", null)
      .order("created_at", { ascending: false }),
    attachmentErrors,
  );
}

const extensions: Record<string, string> = {
  "image/jpeg": "jpg",
  "image/png": "png",
  "application/pdf": "pdf",
};

export async function uploadAttachment(
  db: Db,
  vehicleId: string,
  maintenanceId: string,
  file: File,
): Promise<Attachment> {
  if (!(attachmentTypes as readonly string[]).includes(file.type)) {
    throw new VehicleError("Tipo de arquivo não permitido. Use JPG, PNG ou PDF.");
  }
  if (file.size < 1 || file.size > attachmentMaxBytes) {
    throw new VehicleError("O arquivo deve ter entre 1 byte e 10 MB.");
  }
  const { data: auth } = await db.auth.getUser();
  if (!auth.user) throw new VehicleError("Sua sessão expirou. Entre novamente.");

  const id = crypto.randomUUID();
  const path = `users/${auth.user.id}/vehicles/${vehicleId}/maintenance/${maintenanceId}/${id}.${extensions[file.type]}`;

  const upload = await db.storage
    .from(BUCKET)
    .upload(path, file, { contentType: file.type, upsert: false });
  if (upload.error) throw new VehicleError("Não foi possível enviar o arquivo.");

  try {
    return await run(
      db
        .from("attachments")
        .insert({
          id,
          vehicle_id: vehicleId,
          entity_type: "maintenance",
          entity_id: maintenanceId,
          file_name: file.name.trim().slice(0, 255),
          content_type: file.type,
          file_size: file.size,
          storage_path: path,
        })
        .select()
        .single(),
      attachmentErrors,
    );
  } catch (e) {
    // Compensação: não deixa o arquivo órfão no bucket se o registro falhar.
    await db.storage.from(BUCKET).remove([path]).catch(() => undefined);
    throw e;
  }
}

export async function getAttachmentUrl(db: Db, attachment: Attachment): Promise<string> {
  const { data, error } = await db.storage.from(BUCKET).createSignedUrl(attachment.storage_path, 300);
  if (error || !data) throw new VehicleError("Não foi possível acessar o arquivo.");
  return data.signedUrl;
}

export async function deleteAttachment(db: Db, attachment: Attachment) {
  await db.storage.from(BUCKET).remove([attachment.storage_path]);
  await run(
    db
      .from("attachments")
      .update({ deleted_at: nowIso() })
      .eq("id", attachment.id)
      .select("id")
      .single(),
    attachmentErrors,
  );
}

// ── Catálogo FIPE (opcional; o cadastro manual sempre funciona) ───────────

export type CatalogOption = { code: string; name: string };

const FIPE = "https://fipe.parallelum.com.br/api/v2";

async function fipe(path: string): Promise<CatalogOption[]> {
  const response = await fetch(`${FIPE}${path}`, {
    headers: { accept: "application/json" },
    signal: AbortSignal.timeout(12_000),
  });
  if (!response.ok) throw new VehicleError("O catálogo de veículos está indisponível.");
  const data: unknown = await response.json();
  if (!Array.isArray(data)) throw new VehicleError("Resposta inesperada do catálogo.");
  return (data as { code: string | number; name: string }[])
    .map((o) => ({ code: String(o.code), name: o.name }))
    .sort((a, b) => a.name.localeCompare(b.name, "pt-BR"));
}

const fipeType = (type: string) => (type === "motorcycle" ? "motorcycles" : "cars");

export const listCatalogBrands = (type: string) => fipe(`/${fipeType(type)}/brands`);
export const listCatalogModels = (type: string, brandCode: string) =>
  fipe(`/${fipeType(type)}/brands/${brandCode}/models`);
