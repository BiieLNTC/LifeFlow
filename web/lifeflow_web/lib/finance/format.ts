/**
 * Formatação e parsing de valores/datas de domínio de finanças.
 * Datas de domínio são strings `YYYY-MM-DD` (coluna `date` do Postgres) e nunca
 * passam por `Date`/UTC, para não deslocar o dia por fuso (AGENTS.md §7).
 */

const currency = new Intl.NumberFormat("pt-BR", {
  style: "currency",
  currency: "BRL",
});

export function formatCurrency(value: number): string {
  return currency.format(value);
}

/** Aceita "1.234,56", "1234,56" e "1234.56" (mesma regra do mobile). */
export function parseMoney(input: string): number | null {
  const text = input.trim();
  if (!text) return null;
  const normalized = text.includes(",")
    ? text.replaceAll(".", "").replace(",", ".")
    : text;
  if (!/^\d+(\.\d+)?$/.test(normalized)) return null;
  const value = Number(normalized);
  return Number.isFinite(value) ? Math.round(value * 100) / 100 : null;
}

/** Valor para preencher um campo de edição ("1234,56"). */
export function moneyToInput(value: number): string {
  return value.toFixed(2).replace(".", ",");
}

export function formatDate(iso: string): string {
  const [y, m, d] = iso.split("-");
  return `${d}/${m}/${y}`;
}

const pad = (n: number) => String(n).padStart(2, "0");

export function toIsoDate(year: number, month: number, day: number): string {
  return `${year}-${pad(month)}-${pad(day)}`;
}

export function todayIso(now: Date = new Date()): string {
  return toIsoDate(now.getFullYear(), now.getMonth() + 1, now.getDate());
}

function daysInMonth(year: number, month: number): number {
  return new Date(year, month, 0).getDate();
}

/**
 * Soma meses preservando o dia; se o mês de destino for mais curto, usa o
 * último dia dele (31/01 + 1 mês = 28/02, não 03/03).
 */
export function addMonths(iso: string, months: number): string {
  const [y, m, d] = iso.split("-").map(Number);
  const index = y * 12 + (m - 1) + months;
  const year = Math.floor(index / 12);
  const month = (index % 12) + 1;
  return toIsoDate(year, month, Math.min(d, daysInMonth(year, month)));
}

/** Datas das N parcelas de uma compra parcelada, em meses consecutivos. */
export function installmentDates(firstDate: string, total: number): string[] {
  return Array.from({ length: total }, (_, i) => addMonths(firstDate, i));
}

const monthNames = [
  "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
  "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro",
];

export function monthLabel(year: number, month: number): string {
  return `${monthNames[month - 1]} de ${year}`;
}

export function shiftMonth(
  year: number,
  month: number,
  delta: number,
): { year: number; month: number } {
  const index = year * 12 + (month - 1) + delta;
  return { year: Math.floor(index / 12), month: (index % 12) + 1 };
}
