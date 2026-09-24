"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { navItems } from "@/lib/nav-items";
import { NotificationBadge } from "@/components/notifications/notification-badge";
import { cn } from "@/lib/utils";

export function MobileBottomNav({ className }: { className?: string }) {
  const pathname = usePathname();

  return (
    <nav
      className={cn(
        "fixed inset-x-0 bottom-0 z-40 flex border-t bg-sidebar text-sidebar-foreground",
        className,
      )}
    >
      {navItems.map((item) => {
        const isActive =
          item.href === "/" ? pathname === "/" : pathname.startsWith(item.href);
        const Icon = item.icon;
        return (
          <Link
            key={item.href}
            href={item.href}
            className={cn(
              "flex flex-1 flex-col items-center gap-1 py-2.5 text-[11px] font-medium",
              isActive ? "text-primary" : "text-muted-foreground",
            )}
          >
            <span className="relative">
              <Icon className="size-5" />
              {item.href === "/notifications" && (
                <NotificationBadge className="absolute -top-2 left-3 min-w-4 px-1 text-[10px] leading-4" />
              )}
            </span>
            {item.label}
          </Link>
        );
      })}
    </nav>
  );
}
