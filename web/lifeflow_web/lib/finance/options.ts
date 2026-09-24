import type { Category, Person, TransactionType } from "@/lib/finance/api";
import type { Option } from "@/components/finance/shared";

/** Categorias ativas que servem ao tipo; mantém `keepId` mesmo se removida/incompatível. */
export function categoryOptions(
  categories: Category[],
  type: TransactionType | "any",
  keepId?: string,
): Option[] {
  return categories
    .filter(
      (c) =>
        c.id === keepId ||
        (c.deleted_at === null && (type === "any" || c.purpose === "both" || c.purpose === type)),
    )
    .map((c) => ({ value: c.id, label: c.description }));
}

export function personOptions(people: Person[], keepId?: string): Option[] {
  return people
    .filter((p) => p.id === keepId || p.deleted_at === null)
    .map((p) => ({ value: p.id, label: p.name }));
}
