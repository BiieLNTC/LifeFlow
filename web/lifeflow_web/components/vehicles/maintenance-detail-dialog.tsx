"use client";

import { useRef, useState } from "react";
import { ExternalLink, FileText, Image as ImageIcon, Loader2, Trash2, Upload } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { ConfirmDelete, FormError, SectionTitle } from "@/components/finance/shared";
import { FormDialog } from "@/components/finance/form-dialog";
import { formatCurrency, formatDate } from "@/lib/finance/format";
import { formatFileSize, formatOdometer } from "@/lib/vehicles/format";
import {
  useAttachments,
  useDeleteAttachment,
  useOpenAttachment,
  useUploadAttachment,
} from "@/lib/vehicles/hooks";
import {
  attachmentTypes,
  maintenanceCategoryLabels,
  maintenanceTypeLabels,
} from "@/lib/vehicles/options";
import type { Attachment, Maintenance } from "@/lib/vehicles/api";

export function MaintenanceDetailDialog({
  maintenance,
  onOpenChange,
}: {
  maintenance: Maintenance | null;
  onOpenChange: (open: boolean) => void;
}) {
  return (
    <FormDialog
      open={maintenance !== null}
      onOpenChange={onOpenChange}
      title="Manutenção"
      description={
        maintenance
          ? `${formatDate(maintenance.maintenance_date)} · ${formatOdometer(maintenance.odometer)}`
          : undefined
      }
      className="sm:max-w-2xl"
    >
      {maintenance && <Detail maintenance={maintenance} />}
    </FormDialog>
  );
}

function Detail({ maintenance: m }: { maintenance: Maintenance }) {
  return (
    <div className="flex max-h-[70vh] flex-col gap-5 overflow-y-auto">
      <div className="flex flex-wrap items-center gap-2 text-sm">
        <Badge variant="secondary">
          {maintenanceTypeLabels[m.maintenance_type as keyof typeof maintenanceTypeLabels] ?? m.maintenance_type}
        </Badge>
        {m.workshop && <span className="text-muted-foreground">{m.workshop}</span>}
        <span className="ml-auto font-heading text-xl font-bold tabular-nums">
          {formatCurrency(m.total_amount)}
        </span>
      </div>

      <Table>
        <TableHeader>
          <TableRow className="hover:bg-transparent">
            <TableHead>Item</TableHead>
            <TableHead className="text-right">Peças</TableHead>
            <TableHead className="text-right">Mão de obra</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {m.maintenance_items.map((i) => (
            <TableRow key={i.id}>
              <TableCell className="whitespace-normal">
                <span className="font-medium">{i.description}</span>
                <span className="block text-xs text-muted-foreground">
                  {maintenanceCategoryLabels[i.category as keyof typeof maintenanceCategoryLabels] ?? i.category}
                  {(i.next_replacement_odometer !== null || i.next_replacement_date) &&
                    ` · próxima troca: ${[
                      i.next_replacement_odometer !== null && formatOdometer(i.next_replacement_odometer),
                      i.next_replacement_date && formatDate(i.next_replacement_date),
                    ]
                      .filter(Boolean)
                      .join(" ou ")}`}
                </span>
              </TableCell>
              <TableCell className="text-right tabular-nums">{formatCurrency(i.part_amount)}</TableCell>
              <TableCell className="text-right tabular-nums">{formatCurrency(i.labor_amount)}</TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>

      {m.notes && <p className="text-sm whitespace-pre-line text-muted-foreground">{m.notes}</p>}

      <AttachmentsSection vehicleId={m.vehicle_id} maintenanceId={m.id} />
    </div>
  );
}

function AttachmentsSection({
  vehicleId,
  maintenanceId,
}: {
  vehicleId: string;
  maintenanceId: string;
}) {
  const attachments = useAttachments(maintenanceId);
  const upload = useUploadAttachment();
  const remove = useDeleteAttachment();
  const open = useOpenAttachment();
  const input = useRef<HTMLInputElement>(null);
  const [error, setError] = useState<string | null>(null);
  const [deleting, setDeleting] = useState<Attachment | null>(null);

  async function onFile(file: File | undefined) {
    if (!file) return;
    setError(null);
    try {
      await upload.mutateAsync({ vehicleId, maintenanceId, file });
    } catch (e) {
      setError(e instanceof Error ? e.message : "Não foi possível enviar o arquivo.");
    } finally {
      if (input.current) input.current.value = "";
    }
  }

  async function view(a: Attachment) {
    setError(null);
    try {
      await open(a);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Não foi possível abrir o arquivo.");
    }
  }

  return (
    <section className="flex flex-col gap-3">
      <div className="flex items-center justify-between gap-3">
        <SectionTitle>Anexos</SectionTitle>
        <Button
          type="button"
          variant="outline"
          size="sm"
          disabled={upload.isPending}
          onClick={() => input.current?.click()}
        >
          {upload.isPending ? <Loader2 className="animate-spin" /> : <Upload />} Anexar arquivo
        </Button>
        <input
          ref={input}
          type="file"
          hidden
          accept={attachmentTypes.join(",")}
          onChange={(e) => void onFile(e.target.files?.[0])}
        />
      </div>
      <p className="text-xs text-muted-foreground">Notas e comprovantes em JPG, PNG ou PDF, até 10 MB.</p>
      <FormError message={error} />
      {attachments.isPending ? (
        <Skeleton className="h-10 w-full" />
      ) : attachments.isError ? (
        <p className="text-sm text-critical">Não foi possível carregar os anexos.</p>
      ) : attachments.data.length === 0 ? (
        <p className="text-sm text-muted-foreground">Nenhum anexo.</p>
      ) : (
        <ul className="flex flex-col divide-y rounded-xl border">
          {attachments.data.map((a) => {
            const Icon = a.content_type === "application/pdf" ? FileText : ImageIcon;
            return (
              <li key={a.id} className="flex items-center gap-3 p-2.5">
                <Icon className="size-4 shrink-0 text-muted-foreground" />
                <span className="min-w-0 flex-1 truncate text-sm">{a.file_name}</span>
                <span className="shrink-0 text-xs text-muted-foreground tabular-nums">
                  {formatFileSize(a.file_size)}
                </span>
                <Button
                  type="button"
                  variant="ghost"
                  size="icon-sm"
                  aria-label={`Abrir ${a.file_name}`}
                  onClick={() => void view(a)}
                >
                  <ExternalLink />
                </Button>
                <Button
                  type="button"
                  variant="ghost"
                  size="icon-sm"
                  aria-label={`Excluir ${a.file_name}`}
                  onClick={() => setDeleting(a)}
                >
                  <Trash2 />
                </Button>
              </li>
            );
          })}
        </ul>
      )}
      <ConfirmDelete
        open={deleting !== null}
        onOpenChange={(o) => !o && setDeleting(null)}
        title="Excluir anexo?"
        description={`"${deleting?.file_name ?? ""}" será removido.`}
        onConfirm={async () => {
          if (deleting) await remove.mutateAsync(deleting);
        }}
      />
    </section>
  );
}
