import { z } from "zod";

/** Mesmas regras do app mobile — ver auth_validators.dart. */
const email = z
  .string()
  .trim()
  .min(1, "Informe seu e-mail.")
  .refine((value) => {
    const separator = value.indexOf("@");
    const lastDot = value.lastIndexOf(".");
    return (
      separator > 0 &&
      lastDot > separator + 1 &&
      lastDot !== value.length - 1
    );
  }, "Informe um e-mail válido.");

const strongPassword = z
  .string()
  .min(8, "Use ao menos 8 caracteres, com letras e números.")
  .regex(/[A-Za-z]/, "Use ao menos 8 caracteres, com letras e números.")
  .regex(/[0-9]/, "Use ao menos 8 caracteres, com letras e números.");

export const loginSchema = z.object({
  email,
  password: z.string().min(1, "Informe sua senha."),
});

export const signUpSchema = z.object({
  name: z.string().trim().min(2, "Informe um nome válido."),
  email,
  password: strongPassword,
});

export const forgotPasswordSchema = z.object({
  email,
});

export const updatePasswordSchema = z.object({
  password: strongPassword,
});
