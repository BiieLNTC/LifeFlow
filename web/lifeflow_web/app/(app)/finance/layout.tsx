import { FinanceSubnav } from "@/components/finance/finance-subnav";

export default function FinanceLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="mx-auto max-w-5xl">
      <FinanceSubnav />
      {children}
    </div>
  );
}
