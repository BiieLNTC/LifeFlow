"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { cn } from "@/lib/utils";

const tabs = [
  { href: "/finance", label: "Visão geral" },
  { href: "/finance/transactions", label: "Transações" },
  { href: "/finance/budgets", label: "Orçamentos" },
  { href: "/finance/goals", label: "Metas" },
];

export function FinanceSubnav() {
  const pathname = usePathname();
  return (
    <nav aria-label="Finanças" className="mb-6 flex gap-1 overflow-x-auto border-b">
      {tabs.map((tab) => {
        const active =
          tab.href === "/finance" ? pathname === "/finance" : pathname.startsWith(tab.href);
        return (
          <Link
            key={tab.href}
            href={tab.href}
            aria-current={active ? "page" : undefined}
            className={cn(
              "-mb-px border-b-2 px-3 py-2 text-sm font-medium whitespace-nowrap transition-colors",
              active
                ? "border-primary text-foreground"
                : "border-transparent text-muted-foreground hover:text-foreground",
            )}
          >
            {tab.label}
          </Link>
        );
      })}
    </nav>
  );
}
