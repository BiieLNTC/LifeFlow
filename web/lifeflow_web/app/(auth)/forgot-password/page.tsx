"use client";

import { zodResolver } from "@hookform/resolvers/zod";
import Link from "next/link";
import { useState, useTransition } from "react";
import { useForm } from "react-hook-form";
import { sendPasswordReset } from "@/lib/auth/actions";
import { forgotPasswordSchema } from "@/lib/auth/schemas";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import type { z } from "zod";

type ForgotPasswordValues = z.infer<typeof forgotPasswordSchema>;

export default function ForgotPasswordPage() {
  const [pending, startTransition] = useTransition();
  const [formMessage, setFormMessage] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<ForgotPasswordValues>({
    resolver: zodResolver(forgotPasswordSchema),
  });

  function onSubmit(values: ForgotPasswordValues) {
    setFormMessage(null);
    startTransition(async () => {
      const formData = new FormData();
      formData.set("email", values.email);
      const result = await sendPasswordReset({}, formData);
      if (result?.message) {
        setFormMessage(result.message);
        setSuccess(Boolean(result.success));
      }
    });
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Recuperar senha</CardTitle>
        <CardDescription>
          Enviaremos um link para redefinir sua senha.
        </CardDescription>
      </CardHeader>
      <CardContent>
        <form className="grid gap-4" onSubmit={handleSubmit(onSubmit)} noValidate>
          <div className="grid gap-2">
            <Label htmlFor="email">E-mail</Label>
            <Input id="email" type="email" autoComplete="email" {...register("email")} />
            {errors.email && (
              <p className="text-sm text-critical">{errors.email.message}</p>
            )}
          </div>
          {formMessage && (
            <p className={`text-sm ${success ? "text-primary" : "text-critical"}`}>
              {formMessage}
            </p>
          )}
          <Button type="submit" disabled={pending} className="mt-2">
            {pending ? "Enviando…" : "Enviar link"}
          </Button>
        </form>
      </CardContent>
      <CardFooter className="justify-center text-sm text-muted-foreground">
        <Link href="/login" className="font-medium text-foreground">
          Voltar para o login
        </Link>
      </CardFooter>
    </Card>
  );
}
