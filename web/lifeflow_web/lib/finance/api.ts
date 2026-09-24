import type { PostgrestError, SupabaseClient } from "@supabase/supabase-js";
import type { Database } from "@/lib/supabase/database.types";
import { installmentDates, parseMoney } from "@/lib/finance/format";
import type {
  BudgetValues,
  CategoryValues,
  ContributionValues,
  GoalValues,
  PersonValues,
  RecurringValues,
  TransactionValues,
} from "@/lib/finance/schemas";

type Db = SupabaseClient<Database>;
type Tables = Database["public"]["Tables"];
type Views = Database["public"]["Views"];

export type Category = Tables["categories"]["Row"];
export type Person = Tables["people"]["Row"];
export type Transaction = Tables["transactions"]["Row"];
export type RecurringTransaction = Tables["recurring_transactions"]["Row"];
export type GoalContribution = Tables["goal_contributions"]["Row"];
export type SavingsGoal = Tables["savings_goals"]["Row"] & {
  goal_contributions: Pick<GoalContribution, "id" | "amount" | "contribution_date">[];
};
export type BudgetProgress = Views["budget_progress"]["Row"];
export type FinanceTotals = Views["finance_totals"]["Row"];

export type TransactionType = "expense" | "income";
export type CategoryPurpose = "expense" | "income" | "both";

/** Erro com mensagem já em pt-BR, pronta para exibir. */
export class FinanceError extends Error {}

const nowIso = () => new Date().toISOString();

async function run<T>(
  op: PromiseLike<{ data: T; error: PostgrestError | null }>,
  messages: Partial<Record<string, string>> & { default: string },
): Promise<NonNullable<T>> {
  let result;
  try {
    result = await op;
  } catch {
    throw new FinanceError("Não foi possível conectar ao serviço.");
  }
  if (result.error) {
    const { code } = result.error;
    throw new FinanceError((code && messages[code]) || messages.default);
  }
  // Sem erro, o PostgREST sempre devolve dados (single() já falha em 0 linhas).
  return result.data as NonNullable<T>;
}

const blankToNull = (v: string) => {
  const t = v.trim();
  return t === "" ? null : t;
};

/** Valor já validado pelo schema Zod (`parseMoney` não retorna null aqui). */
const money = (v: string) => parseMoney(v) as number;

// ── Categorias ────────────────────────────────────────────────────────────
// Busca inclusive as removidas: transações antigas ainda referenciam elas.

const categoryErrors = {
  "23505": "Já existe uma categoria com este nome.",
  "42501": "Você não tem permissão para esta categoria.",
  default: "Revise os dados da categoria.",
};

export async function listCategories(db: Db): Promise<Category[]> {
  return run(db.from("categories").select("*").order("description"), categoryErrors);
}

export async function saveCategory(db: Db, id: string | null, v: CategoryValues) {
  const payload = {
    description: v.description.trim(),
    purpose: v.purpose,
    color: blankToNull(v.color),
  };
  return run(
    id
      ? db.from("categories").update(payload).eq("id", id).select().single()
      : db.from("categories").insert(payload).select().single(),
    categoryErrors,
  );
}

export async function deleteCategory(db: Db, id: string) {
  await run(
    db.from("categories").update({ deleted_at: nowIso() }).eq("id", id).select("id").single(),
    categoryErrors,
  );
}

// ── Pessoas ───────────────────────────────────────────────────────────────

const personErrors = {
  "42501": "Você não tem permissão para esta pessoa.",
  default: "Revise os dados da pessoa.",
};

export async function listPeople(db: Db): Promise<Person[]> {
  return run(db.from("people").select("*").order("name"), personErrors);
}

export async function savePerson(db: Db, id: string | null, v: PersonValues) {
  const payload = { name: v.name.trim(), birth_date: blankToNull(v.birthDate) };
  return run(
    id
      ? db.from("people").update(payload).eq("id", id).select().single()
      : db.from("people").insert(payload).select().single(),
    personErrors,
  );
}

export async function deletePerson(db: Db, id: string) {
  await run(
    db.from("people").update({ deleted_at: nowIso() }).eq("id", id).select("id").single(),
    personErrors,
  );
}

// ── Transações ────────────────────────────────────────────────────────────

const transactionErrors = {
  "23505": "Esta transação já existe.",
  "42501":
    "Esta transação foi gerada automaticamente e só pode ser alterada pela origem (veículo ou recorrência).",
  PGRST116:
    "Esta transação foi gerada automaticamente e só pode ser alterada pela origem (veículo ou recorrência).",
  default: "Revise os dados da transação.",
};

/** Transações ativas com data em [from, to] (inclusive), mais recentes primeiro. */
export async function listTransactions(
  db: Db,
  range: { from: string; to: string },
): Promise<Transaction[]> {
  return run(
    db
      .from("transactions")
      .select("*")
      .is("deleted_at", null)
      .gte("transaction_date", range.from)
      .lte("transaction_date", range.to)
      .order("transaction_date", { ascending: false })
      .order("created_at", { ascending: false }),
    transactionErrors,
  );
}

export async function listRecentTransactions(db: Db, limit = 10): Promise<Transaction[]> {
  return run(
    db
      .from("transactions")
      .select("*")
      .is("deleted_at", null)
      .order("transaction_date", { ascending: false })
      .order("created_at", { ascending: false })
      .limit(limit),
    transactionErrors,
  );
}

function transactionFields(v: TransactionValues) {
  return {
    category_id: v.categoryId,
    person_id: blankToNull(v.personId),
    description: v.description.trim(),
    type: v.type,
    amount: money(v.amount),
  };
}

export async function createTransaction(db: Db, v: TransactionValues) {
  await run(
    db
      .from("transactions")
      .insert({ ...transactionFields(v), transaction_date: v.date })
      .select("id")
      .single(),
    transactionErrors,
  );
}

/** Uma única chamada (atômica): ou todas as parcelas entram, ou nenhuma. */
export async function createInstallmentPurchase(db: Db, v: TransactionValues) {
  const total = Number(v.installments);
  const groupId = crypto.randomUUID();
  const rows = installmentDates(v.date, total).map((date, i) => ({
    ...transactionFields(v),
    transaction_date: date,
    installment_group_id: groupId,
    installment_index: i + 1,
    installment_total: total,
  }));
  await run(db.from("transactions").insert(rows).select("id"), transactionErrors);
}

/** Edita só esta transação (parcelas são independentes). */
export async function updateTransaction(db: Db, id: string, v: TransactionValues) {
  await run(
    db
      .from("transactions")
      .update({ ...transactionFields(v), transaction_date: v.date })
      .eq("id", id)
      .select("id")
      .single(),
    transactionErrors,
  );
}

export async function deleteTransaction(db: Db, id: string) {
  await run(
    db.from("transactions").update({ deleted_at: nowIso() }).eq("id", id).select("id").single(),
    transactionErrors,
  );
}

// ── Recorrências ──────────────────────────────────────────────────────────

const recurringErrors = {
  "42501": "Você não tem permissão para esta recorrência.",
  default: "Revise os dados da recorrência.",
};

export async function listRecurring(db: Db): Promise<RecurringTransaction[]> {
  return run(
    db
      .from("recurring_transactions")
      .select("*")
      .is("deleted_at", null)
      .order("created_at", { ascending: false }),
    recurringErrors,
  );
}

export async function saveRecurring(db: Db, id: string | null, v: RecurringValues) {
  const payload = {
    category_id: v.categoryId,
    person_id: blankToNull(v.personId),
    description: v.description.trim(),
    type: v.type,
    amount: money(v.amount),
    day_of_month: Number(v.dayOfMonth),
    start_date: v.startDate,
    end_date: blankToNull(v.endDate),
    paused: v.paused,
  };
  await run(
    id
      ? db.from("recurring_transactions").update(payload).eq("id", id).select("id").single()
      : db.from("recurring_transactions").insert(payload).select("id").single(),
    recurringErrors,
  );
}

/** Cria a recorrência a partir do formulário de transação (início = hoje). */
export async function createRecurringFromTransaction(
  db: Db,
  v: TransactionValues,
  startDate: string,
) {
  await saveRecurring(db, null, {
    type: v.type,
    description: v.description,
    categoryId: v.categoryId,
    personId: v.personId,
    amount: v.amount,
    dayOfMonth: v.dayOfMonth,
    startDate,
    endDate: v.endDate,
    paused: false,
  });
}

export async function deleteRecurring(db: Db, id: string) {
  await run(
    db
      .from("recurring_transactions")
      .update({ deleted_at: nowIso() })
      .eq("id", id)
      .select("id")
      .single(),
    recurringErrors,
  );
}

/** Gera ocorrências pendentes sob demanda (nunca por cron — ROADMAP §1.5). */
export async function generateDueRecurring(db: Db): Promise<number> {
  return run(db.rpc("generate_due_recurring_transactions"), {
    default: "Não foi possível gerar as ocorrências.",
  });
}

// ── Orçamentos ────────────────────────────────────────────────────────────

const budgetErrors = {
  "23505": "Já existe um orçamento para esta categoria neste mês.",
  "42501": "Você não tem permissão para este orçamento.",
  default: "Revise os dados do orçamento.",
};

export async function listBudgetProgress(
  db: Db,
  year: number,
  month: number,
): Promise<BudgetProgress[]> {
  return run(
    db
      .from("budget_progress")
      .select("*")
      .eq("year", year)
      .eq("month", month)
      .order("category_description"),
    budgetErrors,
  );
}

export async function saveBudget(
  db: Db,
  id: string | null,
  period: { year: number; month: number },
  v: BudgetValues,
) {
  const limit_amount = money(v.limitAmount);
  await run(
    id
      ? db
          .from("budgets")
          .update({ category_id: v.categoryId, limit_amount })
          .eq("id", id)
          .select("id")
          .single()
      : db
          .from("budgets")
          .insert({ category_id: v.categoryId, limit_amount, ...period })
          .select("id")
          .single(),
    budgetErrors,
  );
}

export async function deleteBudget(db: Db, id: string) {
  await run(
    db.from("budgets").update({ deleted_at: nowIso() }).eq("id", id).select("id").single(),
    budgetErrors,
  );
}

// ── Totais ────────────────────────────────────────────────────────────────

export async function getFinanceTotals(db: Db): Promise<FinanceTotals> {
  return run(db.from("finance_totals").select("*").single(), {
    default: "Não foi possível carregar o saldo.",
  });
}

// ── Metas de poupança ─────────────────────────────────────────────────────

const goalErrors = {
  "42501": "Você não tem permissão para esta meta.",
  default: "Revise os dados da meta.",
};

/** Metas com seus aportes numa só chamada (embed do PostgREST). */
export async function listGoals(db: Db): Promise<SavingsGoal[]> {
  return run(
    db
      .from("savings_goals")
      .select("*, goal_contributions(id, amount, contribution_date)")
      .is("deleted_at", null)
      .order("created_at", { ascending: false }),
    goalErrors,
  );
}

export async function saveGoal(db: Db, id: string | null, v: GoalValues) {
  const payload = {
    title: v.title.trim(),
    target_amount: money(v.targetAmount),
    target_date: blankToNull(v.targetDate),
  };
  await run(
    id
      ? db.from("savings_goals").update(payload).eq("id", id).select("id").single()
      : db.from("savings_goals").insert(payload).select("id").single(),
    goalErrors,
  );
}

export async function deleteGoal(db: Db, id: string) {
  await run(
    db.from("savings_goals").update({ deleted_at: nowIso() }).eq("id", id).select("id").single(),
    goalErrors,
  );
}

export async function addContribution(db: Db, goalId: string, v: ContributionValues) {
  await run(
    db
      .from("goal_contributions")
      .insert({ goal_id: goalId, amount: money(v.amount), contribution_date: v.date })
      .select("id")
      .single(),
    { ...goalErrors, default: "Revise os dados do aporte." },
  );
}

export async function deleteContribution(db: Db, id: string) {
  await run(db.from("goal_contributions").delete().eq("id", id).select("id"), goalErrors);
}

export function goalSaved(goal: SavingsGoal): number {
  return goal.goal_contributions.reduce((sum, c) => sum + c.amount, 0);
}
