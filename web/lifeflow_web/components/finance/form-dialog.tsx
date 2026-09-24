"use client";

import { useState } from "react";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { FormError, SubmitButton } from "@/components/finance/shared";

/**
 * Casca dos formulários em diálogo. O conteúdo só é montado enquanto aberto,
 * então cada abertura começa com o estado do react-hook-form do zero.
 */
export function FormDialog({
  open,
  onOpenChange,
  title,
  description,
  className,
  children,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  title: string;
  description?: string;
  className?: string;
  children: React.ReactNode;
}) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className={className}>
        <DialogHeader>
          <DialogTitle>{title}</DialogTitle>
          {description && <DialogDescription>{description}</DialogDescription>}
        </DialogHeader>
        {children}
      </DialogContent>
    </Dialog>
  );
}

/** Estado de envio + erro do servidor (já em pt-BR) para um formulário. */
export function useSubmit(onDone: () => void) {
  const [pending, setPending] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function run(fn: () => Promise<unknown>) {
    setPending(true);
    setError(null);
    try {
      await fn();
      onDone();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Não foi possível salvar.");
    } finally {
      setPending(false);
    }
  }
  return { pending, error, run };
}

export function FormFooter({
  pending,
  error,
  submitLabel,
  onCancel,
}: {
  pending: boolean;
  error: string | null;
  submitLabel: string;
  onCancel: () => void;
}) {
  return (
    <>
      <FormError message={error} />
      <DialogFooter>
        <Button type="button" variant="outline" onClick={onCancel} disabled={pending}>
          Cancelar
        </Button>
        <SubmitButton pending={pending}>{submitLabel}</SubmitButton>
      </DialogFooter>
    </>
  );
}
