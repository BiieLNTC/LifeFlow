"use client";

import Link from "next/link";
import { AlertTriangle, ChevronRight, Info, OctagonAlert } from "lucide-react";
import { Card } from "@/components/ui/card";
import {
  EmptyState,
  ErrorState,
  LoadingRows,
  PageHeader,
} from "@/components/finance/shared";
import { formatDate } from "@/lib/finance/format";
import { useNotifications } from "@/lib/notifications/hooks";
import {
  kindLabels,
  notificationHref,
  type NotificationItem,
  type NotificationSeverity,
} from "@/lib/notifications/model";
import { cn } from "@/lib/utils";

const severityStyle: Record<
  NotificationSeverity,
  { icon: typeof Info; tone: string }
> = {
  critical: { icon: OctagonAlert, tone: "bg-critical/10 text-critical" },
  warning: { icon: AlertTriangle, tone: "bg-warning/10 text-warning" },
  info: { icon: Info, tone: "bg-primary/10 text-primary" },
};

export function NotificationsScreen() {
  const notifications = useNotifications();

  return (
    <div className="mx-auto flex max-w-3xl flex-col gap-6">
      <PageHeader
        title="Notificações"
        description="Lembretes, orçamentos, documentos e recorrências que pedem sua atenção."
      />
      {notifications.isPending ? (
        <LoadingRows rows={4} />
      ) : notifications.isError ? (
        <ErrorState
          message="Não foi possível carregar as notificações."
          onRetry={() => void notifications.refetch()}
        />
      ) : notifications.data.length === 0 ? (
        <Card>
          <EmptyState
            title="Tudo em dia."
            description="Nada vencendo, nenhum orçamento no limite e nenhuma recorrência pendente."
          />
        </Card>
      ) : (
        <ul className="flex flex-col gap-2">
          {notifications.data.map((item) => (
            <li key={`${item.kind}:${item.targetId}`}>
              <NotificationRow item={item} />
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

function NotificationRow({ item }: { item: NotificationItem }) {
  const { icon: Icon, tone } = severityStyle[item.severity];
  const href = notificationHref(item);
  const content = (
    <Card
      className={cn(
        "flex-row items-center gap-4 p-4",
        href && "transition-colors hover:bg-accent",
      )}
    >
      <div className={cn("flex size-10 shrink-0 items-center justify-center rounded-xl", tone)}>
        <Icon className="size-5" />
      </div>
      <div className="min-w-0 flex-1">
        <p className="truncate font-medium">{item.title}</p>
        <p className="text-sm text-muted-foreground">
          {kindLabels[item.kind]} · {item.subtitle}
          {item.dueDate && ` · ${formatDate(item.dueDate)}`}
        </p>
      </div>
      {href && <ChevronRight className="size-4 shrink-0 text-muted-foreground" />}
    </Card>
  );
  if (!href) return content;
  return <Link href={href}>{content}</Link>;
}
