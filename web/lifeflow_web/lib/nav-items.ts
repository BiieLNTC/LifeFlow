import type { LucideIcon } from "lucide-react";
import {
  Bell,
  Car,
  Home,
  MoreHorizontal,
  Wallet,
} from "lucide-react";

export type NavItem = {
  href: string;
  label: string;
  icon: LucideIcon;
};

/** Mesma IA do mobile, adaptada à largura — ver AGENTS.md §12. */
export const navItems: NavItem[] = [
  { href: "/", label: "Início", icon: Home },
  { href: "/finance", label: "Finanças", icon: Wallet },
  { href: "/vehicles", label: "Veículos", icon: Car },
  { href: "/notifications", label: "Notificações", icon: Bell },
  { href: "/more", label: "Mais", icon: MoreHorizontal },
];
