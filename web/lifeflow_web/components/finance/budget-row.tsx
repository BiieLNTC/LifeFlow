import { ProgressBar, type BarStatus } from "@/components/finance/shared";
import { formatCurrency } from "@/lib/finance/format";
import type { BudgetProgress } from "@/lib/finance/api";
import { cn } from "@/lib/utils";

const statusText: Record<BarStatus, string> = {
  normal: "text-muted-foreground",
  warning: "text-warning",
  critical: "text-critical",
};

/** Gasto x limite de um orçamento; o status (normal/warning/critical) vem da view. */
export function BudgetRow({ budget }: { budget: BudgetProgress }) {
  const status = (budget.status ?? "normal") as BarStatus;
  const spent = budget.spent_amount ?? 0;
  const limit = budget.limit_amount ?? 0;
  const percent = budget.percentage ?? 0;
  return (
    <div className="flex flex-col gap-1.5">
      <div className="flex items-baseline justify-between gap-3">
        <span className="truncate text-sm font-medium">{budget.category_description}</span>
        <span className={cn("shrink-0 text-xs font-medium tabular-nums", statusText[status])}>
          {Math.round(percent)}%
        </span>
      </div>
      <ProgressBar percent={percent} status={status} />
      <p className="text-xs text-muted-foreground tabular-nums">
        {formatCurrency(spent)} de {formatCurrency(limit)}
        {spent > limit && ` · ${formatCurrency(spent - limit)} acima do limite`}
      </p>
    </div>
  );
}
