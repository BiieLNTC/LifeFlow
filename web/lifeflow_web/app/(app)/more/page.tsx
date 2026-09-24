import Link from "next/link";
import {
  ChevronRight,
  LogOut,
  Palette,
  PiggyBank,
  Repeat,
  Users,
  Wallet2,
} from "lucide-react";
import { signOut } from "@/lib/auth/actions";
import { createClient } from "@/lib/supabase/server";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Card } from "@/components/ui/card";

export default async function MorePage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  const name = (user?.user_metadata?.name as string | undefined)?.trim();
  const label = name || user?.email?.split("@")[0] || "Seu perfil";

  return (
    <div className="mx-auto max-w-lg">
      <h1 className="font-heading text-2xl font-bold">Mais</h1>

      <Card className="mt-6 flex-row items-center gap-4 p-4">
        <Avatar className="size-12">
          <AvatarFallback>{label.slice(0, 1).toUpperCase()}</AvatarFallback>
        </Avatar>
        <div className="min-w-0">
          <p className="truncate font-medium">{label}</p>
          {user?.email && (
            <p className="truncate text-sm text-muted-foreground">{user.email}</p>
          )}
        </div>
      </Card>

      <p className="mt-8 mb-2 text-xs font-semibold tracking-widest text-muted-foreground">
        FINANÇAS
      </p>
      <div className="flex flex-col gap-2">
        <NavRow href="/more/categories" icon={Wallet2} label="Categorias" />
        <NavRow href="/more/people" icon={Users} label="Pessoas" />
        <NavRow href="/more/recurring" icon={Repeat} label="Transações recorrentes" />
        <NavRow href="/finance/goals" icon={PiggyBank} label="Metas de poupança" />
      </div>

      <p className="mt-8 mb-2 text-xs font-semibold tracking-widest text-muted-foreground">
        PREFERÊNCIAS
      </p>
      <div className="flex flex-col gap-2">
        <Link href="/more/appearance">
          <Card className="flex-row items-center gap-3 p-4 transition-colors hover:bg-accent">
            <Palette className="size-4 text-primary" />
            <span className="flex-1 text-sm font-medium">Aparência</span>
            <ChevronRight className="size-4 text-muted-foreground" />
          </Card>
        </Link>
      </div>

      <p className="mt-8 mb-2 text-xs font-semibold tracking-widest text-muted-foreground">
        CONTA
      </p>
      <form action={signOut}>
        <button type="submit" className="w-full text-left">
          <Card className="flex-row items-center gap-3 p-4 text-critical transition-colors hover:bg-accent">
            <LogOut className="size-4" />
            <span className="flex-1 text-sm font-medium">Sair</span>
          </Card>
        </button>
      </form>
    </div>
  );
}

function NavRow({
  href,
  icon: Icon,
  label,
}: {
  href: string;
  icon: typeof Wallet2;
  label: string;
}) {
  return (
    <Link href={href}>
      <Card className="flex-row items-center gap-3 p-4 transition-colors hover:bg-accent">
        <Icon className="size-4 text-primary" />
        <span className="flex-1 text-sm font-medium">{label}</span>
        <ChevronRight className="size-4 text-muted-foreground" />
      </Card>
    </Link>
  );
}
