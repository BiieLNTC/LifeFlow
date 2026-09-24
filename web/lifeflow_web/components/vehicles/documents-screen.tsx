"use client";

import { useState } from "react";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { ConfirmDelete } from "@/components/finance/shared";
import { DocumentDialog } from "@/components/vehicles/document-dialog";
import { ListSection, RowActions, UrgencyBadge, documentUrgency } from "@/components/vehicles/shared";
import { formatDate, todayIso } from "@/lib/finance/format";
import { daysUntil } from "@/lib/vehicles/format";
import { useDeleteDocument, useDocuments } from "@/lib/vehicles/hooks";
import { documentTypeLabels } from "@/lib/vehicles/options";
import type { VehicleDocument } from "@/lib/vehicles/api";

export function DocumentsScreen({ vehicleId }: { vehicleId: string }) {
  const documents = useDocuments(vehicleId);
  const remove = useDeleteDocument();
  const [creating, setCreating] = useState(false);
  const [editing, setEditing] = useState<VehicleDocument | null>(null);
  const [deleting, setDeleting] = useState<VehicleDocument | null>(null);
  const data = documents.data ?? [];
  const today = todayIso();

  return (
    <>
      <ListSection
        title="Documentos"
        description="Vencimentos de seguro, licenciamento e vistoria."
        actionLabel="Novo documento"
        onAction={() => setCreating(true)}
        query={documents}
        isEmpty={data.length === 0}
        emptyTitle="Nenhum documento cadastrado."
        emptyDescription="Cadastre o vencimento do seguro e do licenciamento para ser avisado."
        errorMessage="Não foi possível carregar os documentos."
      >
        <Table>
          <TableHeader>
            <TableRow className="hover:bg-transparent">
              <TableHead>Documento</TableHead>
              <TableHead className="hidden md:table-cell">Emissão</TableHead>
              <TableHead>Vencimento</TableHead>
              <TableHead className="w-24" />
            </TableRow>
          </TableHeader>
          <TableBody>
            {data.map((d) => {
              const days = d.expiry_date ? daysUntil(d.expiry_date, today) : null;
              return (
                <TableRow key={d.id}>
                  <TableCell className="max-w-72 whitespace-normal">
                    <span className="font-medium">{d.description}</span>
                    <span className="block text-xs text-muted-foreground">
                      {documentTypeLabels[d.type as keyof typeof documentTypeLabels] ?? d.type}
                    </span>
                  </TableCell>
                  <TableCell className="hidden text-muted-foreground md:table-cell">
                    {d.issue_date ? formatDate(d.issue_date) : "—"}
                  </TableCell>
                  <TableCell className="whitespace-normal">
                    {d.expiry_date ? (
                      <div className="flex flex-wrap items-center gap-2">
                        <span className="tabular-nums">{formatDate(d.expiry_date)}</span>
                        {days !== null && days <= 30 && (
                          <UrgencyBadge status={documentUrgency(days)} />
                        )}
                      </div>
                    ) : (
                      <span className="text-muted-foreground">Sem vencimento</span>
                    )}
                  </TableCell>
                  <TableCell>
                    <RowActions
                      label={d.description}
                      onEdit={() => setEditing(d)}
                      onDelete={() => setDeleting(d)}
                    />
                  </TableCell>
                </TableRow>
              );
            })}
          </TableBody>
        </Table>
      </ListSection>
      <DocumentDialog vehicleId={vehicleId} open={creating} onOpenChange={setCreating} />
      <DocumentDialog
        vehicleId={vehicleId}
        open={editing !== null}
        onOpenChange={(o) => !o && setEditing(null)}
        initial={editing}
      />
      <ConfirmDelete
        open={deleting !== null}
        onOpenChange={(o) => !o && setDeleting(null)}
        title="Excluir documento?"
        description={`"${deleting?.description ?? ""}" será removido.`}
        onConfirm={async () => {
          if (deleting) await remove.mutateAsync(deleting.id);
        }}
      />
    </>
  );
}
