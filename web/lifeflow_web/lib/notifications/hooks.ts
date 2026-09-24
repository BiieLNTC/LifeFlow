"use client";

import { useMemo } from "react";
import { useQuery } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import { listNotifications } from "@/lib/notifications/api";
import { highestSeverity } from "@/lib/notifications/model";

/**
 * Vive sob a raiz `["finance"]` de propósito: toda escrita de finanças e de
 * veículos já invalida essa raiz, então a central e o badge se atualizam
 * sozinhos sem tocar nos hooks de mutação existentes.
 */
export function useNotifications() {
  const db = useMemo(() => createClient(), []);
  return useQuery({
    queryKey: ["finance", "notifications"],
    queryFn: () => listNotifications(db),
    refetchOnWindowFocus: true,
  });
}

/** Contagem e severidade para o badge do sino; zera enquanto carrega ou em erro. */
export function useNotificationBadge() {
  const { data } = useNotifications();
  return {
    count: data?.length ?? 0,
    severity: data ? highestSeverity(data) : null,
  };
}
