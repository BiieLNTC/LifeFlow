"use client";

import { useMemo } from "react";
import {
  useMutation,
  useQuery,
  useQueryClient,
  type QueryKey,
} from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import * as api from "@/lib/finance/api";
import { todayIso } from "@/lib/finance/format";

const root = ["finance"] as const;

/** Um client por aba; o browser client do Supabase é leve e stateless. */
function useDb() {
  return useMemo(() => createClient(), []);
}

function useFinanceQuery<T>(key: QueryKey, fn: (db: ReturnType<typeof createClient>) => Promise<T>) {
  const db = useDb();
  return useQuery({ queryKey: [...root, ...key], queryFn: () => fn(db) });
}

// Qualquer escrita pode mexer em saldo, orçamentos e listas: invalida tudo de finanças.
function useFinanceMutation<V, R = void>(
  fn: (db: ReturnType<typeof createClient>, vars: V) => Promise<R>,
) {
  const db = useDb();
  const client = useQueryClient();
  return useMutation({
    mutationFn: (vars: V) => fn(db, vars),
    onSuccess: () => client.invalidateQueries({ queryKey: root }),
  });
}

// ── Leituras ──────────────────────────────────────────────────────────────

export const useCategories = () => useFinanceQuery(["categories"], api.listCategories);
export const usePeople = () => useFinanceQuery(["people"], api.listPeople);
export const useRecurring = () => useFinanceQuery(["recurring"], api.listRecurring);
export const useGoals = () => useFinanceQuery(["goals"], api.listGoals);
export const useTotals = () => useFinanceQuery(["totals"], api.getFinanceTotals);

export const useTransactions = (range: { from: string; to: string }) =>
  useFinanceQuery(["transactions", range.from, range.to], (db) =>
    api.listTransactions(db, range),
  );

export const useRecentTransactions = (limit = 10) =>
  useFinanceQuery(["transactions", "recent", limit], (db) =>
    api.listRecentTransactions(db, limit),
  );

export const useBudgetProgress = (year: number, month: number) =>
  useFinanceQuery(["budgets", year, month], (db) =>
    api.listBudgetProgress(db, year, month),
  );

// ── Escritas ──────────────────────────────────────────────────────────────

export const useSaveCategory = () =>
  useFinanceMutation((db, v: { id: string | null; values: Parameters<typeof api.saveCategory>[2] }) =>
    api.saveCategory(db, v.id, v.values),
  );
export const useDeleteCategory = () => useFinanceMutation(api.deleteCategory);

export const useSavePerson = () =>
  useFinanceMutation((db, v: { id: string | null; values: Parameters<typeof api.savePerson>[2] }) =>
    api.savePerson(db, v.id, v.values),
  );
export const useDeletePerson = () => useFinanceMutation(api.deletePerson);

export const useSaveTransaction = () =>
  useFinanceMutation(
    async (
      db,
      v: { id: string | null; values: Parameters<typeof api.createTransaction>[1] },
    ) => {
      const { values } = v;
      if (v.id) return api.updateTransaction(db, v.id, values);
      if (values.mode === "installment") return api.createInstallmentPurchase(db, values);
      if (values.mode === "recurring") {
        await api.createRecurringFromTransaction(db, values, todayIso());
        // Já materializa a ocorrência de hoje, se o dia do mês coincidir.
        await api.generateDueRecurring(db);
        return;
      }
      return api.createTransaction(db, values);
    },
  );
export const useDeleteTransaction = () => useFinanceMutation(api.deleteTransaction);

export const useSaveRecurring = () =>
  useFinanceMutation((db, v: { id: string | null; values: Parameters<typeof api.saveRecurring>[2] }) =>
    api.saveRecurring(db, v.id, v.values),
  );
export const useDeleteRecurring = () => useFinanceMutation(api.deleteRecurring);
export const useGenerateRecurring = () => useFinanceMutation((db) => api.generateDueRecurring(db));

export const useSaveBudget = () =>
  useFinanceMutation(
    (
      db,
      v: {
        id: string | null;
        period: { year: number; month: number };
        values: Parameters<typeof api.saveBudget>[3];
      },
    ) => api.saveBudget(db, v.id, v.period, v.values),
  );
export const useDeleteBudget = () => useFinanceMutation(api.deleteBudget);

export const useSaveGoal = () =>
  useFinanceMutation((db, v: { id: string | null; values: Parameters<typeof api.saveGoal>[2] }) =>
    api.saveGoal(db, v.id, v.values),
  );
export const useDeleteGoal = () => useFinanceMutation(api.deleteGoal);
export const useAddContribution = () =>
  useFinanceMutation((db, v: { goalId: string; values: Parameters<typeof api.addContribution>[2] }) =>
    api.addContribution(db, v.goalId, v.values),
  );
export const useDeleteContribution = () => useFinanceMutation(api.deleteContribution);
