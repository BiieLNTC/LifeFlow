"use client";

import { useMemo } from "react";
import {
  useInfiniteQuery,
  useMutation,
  useQuery,
  useQueryClient,
  type QueryKey,
} from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import * as api from "@/lib/vehicles/api";

const root = ["vehicles"] as const;

type Db = ReturnType<typeof createClient>;

function useDb() {
  return useMemo(() => createClient(), []);
}

function useVehicleQuery<T>(key: QueryKey, fn: (db: Db) => Promise<T>, enabled = true) {
  const db = useDb();
  return useQuery({ queryKey: [...root, ...key], queryFn: () => fn(db), enabled });
}

// Manutenção, abastecimento e despesa mexem no odômetro, no dashboard, na
// timeline e (por trigger) nas transações de finanças: invalida os dois domínios.
function useVehicleMutation<V, R = void>(fn: (db: Db, vars: V) => Promise<R>) {
  const db = useDb();
  const client = useQueryClient();
  return useMutation({
    mutationFn: (vars: V) => fn(db, vars),
    onSuccess: () =>
      Promise.all([
        client.invalidateQueries({ queryKey: root }),
        client.invalidateQueries({ queryKey: ["finance"] }),
      ]),
  });
}

// ── Leituras ──────────────────────────────────────────────────────────────

export const useVehicles = () => useVehicleQuery(["list"], api.listVehicles);
export const useDashboards = () => useVehicleQuery(["dashboards"], api.listDashboards);
export const useVehicle = (id: string) =>
  useVehicleQuery(["detail", id], (db) => api.getVehicle(db, id));
export const useDashboard = (id: string) =>
  useVehicleQuery(["dashboard", id], (db) => api.getDashboard(db, id));
export const useMaintenances = (id: string) =>
  useVehicleQuery([id, "maintenances"], (db) => api.listMaintenances(db, id));
export const useRefuelings = (id: string) =>
  useVehicleQuery([id, "refuelings"], (db) => api.listRefuelings(db, id));
export const useExpenses = (id: string) =>
  useVehicleQuery([id, "expenses"], (db) => api.listExpenses(db, id));
export const useReminders = (id: string) =>
  useVehicleQuery([id, "reminders"], (db) => api.listReminders(db, id));
export const useDocuments = (id: string) =>
  useVehicleQuery([id, "documents"], (db) => api.listDocuments(db, id));
export const useTrips = (id: string) =>
  useVehicleQuery([id, "trips"], (db) => api.listTrips(db, id));
export const useAttachments = (maintenanceId: string) =>
  useVehicleQuery(["attachments", maintenanceId], (db) => api.listAttachments(db, maintenanceId));

export function useTimeline(vehicleId: string) {
  const db = useDb();
  return useInfiniteQuery({
    queryKey: [...root, vehicleId, "timeline"],
    initialPageParam: 0,
    queryFn: ({ pageParam }) => api.listTimeline(db, vehicleId, pageParam),
    getNextPageParam: (last, pages) =>
      last.length < api.TIMELINE_PAGE_SIZE ? undefined : pages.length * api.TIMELINE_PAGE_SIZE,
  });
}

// ── Escritas ──────────────────────────────────────────────────────────────

type SaveVars<V> = { vehicleId: string; id: string | null; values: V };

export const useSaveVehicle = () =>
  useVehicleMutation((db, v: { id: string | null; values: Parameters<typeof api.saveVehicle>[2] }) =>
    api.saveVehicle(db, v.id, v.values),
  );
export const useDeleteVehicle = () => useVehicleMutation(api.deleteVehicle);

export const useSaveMaintenance = () =>
  useVehicleMutation((db, v: SaveVars<Parameters<typeof api.saveMaintenance>[3]>) =>
    api.saveMaintenance(db, v.vehicleId, v.id, v.values),
  );
export const useDeleteMaintenance = () => useVehicleMutation(api.deleteMaintenance);

export const useSaveRefueling = () =>
  useVehicleMutation((db, v: SaveVars<Parameters<typeof api.saveRefueling>[3]>) =>
    api.saveRefueling(db, v.vehicleId, v.id, v.values),
  );
export const useDeleteRefueling = () => useVehicleMutation(api.deleteRefueling);

export const useSaveExpense = () =>
  useVehicleMutation((db, v: SaveVars<Parameters<typeof api.saveExpense>[3]>) =>
    api.saveExpense(db, v.vehicleId, v.id, v.values),
  );
export const useDeleteExpense = () => useVehicleMutation(api.deleteExpense);

export const useSaveReminder = () =>
  useVehicleMutation((db, v: SaveVars<Parameters<typeof api.saveReminder>[3]>) =>
    api.saveReminder(db, v.vehicleId, v.id, v.values),
  );
export const useSetReminderCompleted = () =>
  useVehicleMutation((db, v: { id: string; completed: boolean }) =>
    api.setReminderCompleted(db, v.id, v.completed),
  );
export const useDeleteReminder = () => useVehicleMutation(api.deleteReminder);
export const useCreateRemindersFromMaintenance = () =>
  useVehicleMutation(
    (db, v: { vehicleId: string; maintenanceId: string; suggestions: api.ReminderSuggestion[] }) =>
      api.createRemindersFromMaintenance(db, v.vehicleId, v.maintenanceId, v.suggestions),
  );

export const useSaveDocument = () =>
  useVehicleMutation((db, v: SaveVars<Parameters<typeof api.saveDocument>[3]>) =>
    api.saveDocument(db, v.vehicleId, v.id, v.values),
  );
export const useDeleteDocument = () => useVehicleMutation(api.deleteDocument);

export const useSaveTrip = () =>
  useVehicleMutation((db, v: SaveVars<Parameters<typeof api.saveTrip>[3]>) =>
    api.saveTrip(db, v.vehicleId, v.id, v.values),
  );
export const useDeleteTrip = () => useVehicleMutation(api.deleteTrip);

export const useUploadAttachment = () =>
  useVehicleMutation((db, v: { vehicleId: string; maintenanceId: string; file: File }) =>
    api.uploadAttachment(db, v.vehicleId, v.maintenanceId, v.file),
  );
export const useDeleteAttachment = () => useVehicleMutation(api.deleteAttachment);

/** Abre o anexo via URL assinada (5 min) numa nova aba. */
export function useOpenAttachment() {
  const db = useDb();
  return async (attachment: api.Attachment) => {
    const url = await api.getAttachmentUrl(db, attachment);
    window.open(url, "_blank", "noopener,noreferrer");
  };
}

/** Catálogo FIPE: cache longo, falha silenciosa (o campo continua livre). */
export function useCatalogBrands(type: string) {
  return useQuery({
    queryKey: ["catalog", type, "brands"],
    queryFn: () => api.listCatalogBrands(type),
    staleTime: Infinity,
    retry: false,
  });
}

export function useCatalogModels(type: string, brandCode: string | undefined) {
  return useQuery({
    queryKey: ["catalog", type, "models", brandCode],
    queryFn: () => api.listCatalogModels(type, brandCode as string),
    enabled: Boolean(brandCode),
    staleTime: Infinity,
    retry: false,
  });
}
