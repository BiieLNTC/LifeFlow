import { z } from "zod";
import { parseMoney, todayIso } from "@/lib/finance/format";

const money = (message = "Informe um valor válido.") =>
  z.string().refine((v) => {
    const n = parseMoney(v);
    return n !== null && n > 0;
  }, message);

const isoDate = z.string().regex(/^\d{4}-\d{2}-\d{2}$/, "Informe a data.");

export const categorySchema = z.object({
  description: z.string().trim().min(1, "Informe a descrição.").max(80),
  purpose: z.enum(["expense", "income", "both"]),
  color: z
    .string()
    .trim()
    .refine((v) => v === "" || /^#[0-9A-Fa-f]{6}$/.test(v), "Use o formato #RRGGBB."),
});
export type CategoryValues = z.infer<typeof categorySchema>;

export const personSchema = z.object({
  name: z.string().trim().min(1, "Informe o nome.").max(120),
  birthDate: z
    .string()
    .refine(
      (v) => v === "" || (/^\d{4}-\d{2}-\d{2}$/.test(v) && v <= todayIso()),
      "Data inválida.",
    ),
});
export type PersonValues = z.infer<typeof personSchema>;

export const transactionSchema = z
  .object({
    mode: z.enum(["single", "installment", "recurring"]),
    type: z.enum(["expense", "income"]),
    description: z.string().trim().min(1, "Informe a descrição.").max(160),
    categoryId: z.string().min(1, "Selecione uma categoria."),
    personId: z.string(), // "" = ninguém
    amount: money(),
    date: z.string(),
    installments: z.string(),
    dayOfMonth: z.string(),
    endDate: z.string(),
  })
  .superRefine((v, ctx) => {
    if (v.mode === "recurring") {
      const n = Number(v.dayOfMonth);
      if (!Number.isInteger(n) || n < 1 || n > 28) {
        ctx.addIssue({ code: "custom", path: ["dayOfMonth"], message: "Dia entre 1 e 28." });
      }
      if (v.endDate && v.endDate < todayIso()) {
        ctx.addIssue({ code: "custom", path: ["endDate"], message: "O fim deve ser futuro." });
      }
      return;
    }
    if (!isoDate.safeParse(v.date).success) {
      ctx.addIssue({ code: "custom", path: ["date"], message: "Informe a data." });
    } else if (v.date > todayIso()) {
      ctx.addIssue({ code: "custom", path: ["date"], message: "A data não pode ser futura." });
    }
    if (v.mode === "installment") {
      const n = Number(v.installments);
      if (!Number.isInteger(n) || n < 2 || n > 120) {
        ctx.addIssue({ code: "custom", path: ["installments"], message: "Entre 2 e 120 parcelas." });
      }
    }
  });
export type TransactionValues = z.infer<typeof transactionSchema>;

export const recurringSchema = z
  .object({
    type: z.enum(["expense", "income"]),
    description: z.string().trim().min(1, "Informe a descrição.").max(160),
    categoryId: z.string().min(1, "Selecione uma categoria."),
    personId: z.string(),
    amount: money(),
    dayOfMonth: z.string().refine((v) => {
      const n = Number(v);
      return Number.isInteger(n) && n >= 1 && n <= 28;
    }, "Dia entre 1 e 28."),
    startDate: isoDate,
    endDate: z.string(),
    paused: z.boolean(),
  })
  .refine((v) => v.endDate === "" || v.endDate >= v.startDate, {
    path: ["endDate"],
    message: "O fim não pode ser antes do início.",
  });
export type RecurringValues = z.infer<typeof recurringSchema>;

export const budgetSchema = z.object({
  categoryId: z.string().min(1, "Selecione uma categoria."),
  limitAmount: money(),
});
export type BudgetValues = z.infer<typeof budgetSchema>;

export const goalSchema = z.object({
  title: z.string().trim().min(1, "Informe o título.").max(120),
  targetAmount: money(),
  targetDate: z.string(),
});
export type GoalValues = z.infer<typeof goalSchema>;

export const contributionSchema = z.object({
  amount: money(),
  date: isoDate.refine((v) => v <= todayIso(), "A data não pode ser futura."),
});
export type ContributionValues = z.infer<typeof contributionSchema>;
