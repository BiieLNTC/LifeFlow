/**
 * Formatação e parsing de valores de veículos. Dinheiro e datas de domínio
 * reaproveitam `lib/finance/format.ts` (strings `YYYY-MM-DD`, nunca `Date`/UTC).
 */

const integer = new Intl.NumberFormat("pt-BR", { maximumFractionDigits: 0 });
const decimal = new Intl.NumberFormat("pt-BR", {
  minimumFractionDigits: 1,
  maximumFractionDigits: 2,
});

export function formatOdometer(km: number): string {
  return `${integer.format(km)} km`;
}

export function formatConsumption(kmPerLiter: number): string {
  return `${decimal.format(kmPerLiter)} km/l`;
}

export function formatFileSize(bytes: number): string {
  if (bytes < 1024 * 1024) return `${Math.max(1, Math.round(bytes / 1024))} KB`;
  return `${(bytes / 1024 / 1024).toFixed(1).replace(".", ",")} MB`;
}

export function formatLiters(liters: number): string {
  return `${liters.toLocaleString("pt-BR", { maximumFractionDigits: 3 })} L`;
}

/** Aceita "12,5", "1.234,567" e "12.5"; não arredonda (litros têm 3 casas). */
export function parseDecimal(input: string): number | null {
  const text = input.trim();
  if (!text) return null;
  const normalized = text.includes(",")
    ? text.replaceAll(".", "").replace(",", ".")
    : text;
  if (!/^\d+(\.\d+)?$/.test(normalized)) return null;
  const value = Number(normalized);
  return Number.isFinite(value) ? value : null;
}

/** Inteiro não negativo ("1.234" ou "1234"); null se vazio ou inválido. */
export function parseInteger(input: string): number | null {
  const text = input.trim().replaceAll(".", "");
  if (!/^\d+$/.test(text)) return null;
  const value = Number(text);
  return Number.isSafeInteger(value) ? value : null;
}

export function decimalToInput(value: number, digits: number): string {
  return value.toFixed(digits).replace(".", ",");
}

/** Placa em maiúsculas, sem hífen/espaço (mesma regra do mobile). */
export function normalizePlate(input: string): string {
  return input.replace(/[^a-zA-Z0-9]/g, "").toUpperCase();
}

/** Padrão antigo (ABC1234) e Mercosul (ABC1D23). */
export const plateRegex = /^[A-Z]{3}[0-9][A-Z0-9][0-9]{2}$/;

export function formatPlate(plate: string): string {
  return /^[A-Z]{3}[0-9]{4}$/.test(plate) ? `${plate.slice(0, 3)}-${plate.slice(3)}` : plate;
}

export type RefuelingInputs = { liters: string; unitPrice: string; total: string };
export type RefuelingSource = keyof RefuelingInputs;

/**
 * Recalcula o campo derivado do abastecimento (litros × preço = total), mesma
 * regra do mobile: editar o total recalcula o preço; editar litros ou preço
 * recalcula o total (ou o preço, se só o total existir).
 */
export function recalcRefueling(
  source: RefuelingSource,
  v: RefuelingInputs,
): Partial<RefuelingInputs> {
  const liters = parseDecimal(v.liters);
  const price = parseDecimal(v.unitPrice);
  const total = parseDecimal(v.total);
  const hasL = liters !== null && liters > 0;
  const hasP = price !== null && price > 0;
  const hasT = total !== null && total > 0;

  if (source === "total" && hasL && hasT) {
    return { unitPrice: decimalToInput(total / liters, 4) };
  }
  if (source !== "total" && hasL && hasP) {
    return { total: decimalToInput(liters * price, 2) };
  }
  if (hasL && hasT && !hasP) {
    return { unitPrice: decimalToInput(total / liters, 4) };
  }
  return {};
}

/** Regra do banco: |total − round(litros × preço, 2)| ≤ 0,01. */
export function refuelingTotalMatches(liters: number, unitPrice: number, total: number): boolean {
  return Math.abs(total - Math.round(liters * unitPrice * 100) / 100) <= 0.01 + 1e-9;
}

/** `datetime-local` (hora local, sem fuso) → ISO UTC para colunas timestamptz. */
export function localInputToIso(local: string): string {
  return new Date(local).toISOString();
}

/** ISO → valor de `datetime-local` na hora local do navegador. */
export function isoToLocalInput(iso: string): string {
  const d = new Date(iso);
  const pad = (n: number) => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

export function nowLocalInput(): string {
  return isoToLocalInput(new Date().toISOString());
}

export function formatDateTime(iso: string): string {
  return new Date(iso).toLocaleString("pt-BR", { dateStyle: "short", timeStyle: "short" });
}

/** Dias entre hoje e uma data de domínio (negativo = já passou). */
export function daysUntil(isoDate: string, today: string): number {
  const toUtc = (s: string) => {
    const [y, m, d] = s.split("-").map(Number);
    return Date.UTC(y, m - 1, d);
  };
  return Math.round((toUtc(isoDate) - toUtc(today)) / 86_400_000);
}
