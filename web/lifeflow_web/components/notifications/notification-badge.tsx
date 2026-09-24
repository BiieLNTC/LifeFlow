"use client";

import { useNotificationBadge } from "@/lib/notifications/hooks";
import { cn } from "@/lib/utils";

/** Contador do sino; some quando não há nada pendente. Cor pela pior severidade. */
export function NotificationBadge({ className }: { className?: string }) {
  const { count, severity } = useNotificationBadge();
  if (count === 0) return null;
  return (
    <span
      aria-label={`${count} ${count === 1 ? "notificação" : "notificações"}`}
      className={cn(
        "inline-flex min-w-5 items-center justify-center rounded-full px-1.5 text-[11px] leading-5 font-bold tabular-nums",
        severity === "critical" && "bg-critical text-white",
        severity === "warning" && "bg-warning text-background",
        severity !== "critical" && severity !== "warning" && "bg-primary text-primary-foreground",
        className,
      )}
    >
      {count > 99 ? "99+" : count}
    </span>
  );
}
