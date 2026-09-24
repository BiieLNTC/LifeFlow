"use client";

import { useTheme } from "next-themes";
import { Check, Laptop, Moon, Sun } from "lucide-react";
import { Card } from "@/components/ui/card";
import { cn } from "@/lib/utils";

const options = [
  { value: "system", label: "Automático", description: "Segue o tema do sistema", icon: Laptop },
  { value: "light", label: "Claro", icon: Sun },
  { value: "dark", label: "Escuro", icon: Moon },
] as const;

export default function AppearancePage() {
  // `theme` fica undefined até o next-themes montar e ler o valor
  // persistido — mesmo valor no server e no primeiro render do client,
  // então não há mismatch de hidratação sem precisar de estado próprio.
  const { theme, setTheme } = useTheme();

  return (
    <div className="mx-auto max-w-lg">
      <h1 className="font-heading text-2xl font-bold">Aparência</h1>
      <p className="mt-1 text-muted-foreground">
        Escolha como o LifeFlow deve aparecer neste navegador.
      </p>

      <div className="mt-6 flex flex-col gap-2">
        {options.map((option) => {
          const Icon = option.icon;
          const selected = theme === option.value;
          return (
            <Card
              key={option.value}
              role="button"
              tabIndex={0}
              onClick={() => setTheme(option.value)}
              onKeyDown={(event) => {
                if (event.key === "Enter" || event.key === " ") {
                  setTheme(option.value);
                }
              }}
              className={cn(
                "flex-row items-center gap-3 p-4 transition-colors hover:bg-accent",
                selected && "ring-2 ring-primary",
              )}
            >
              <Icon className="size-4" />
              <div className="flex-1">
                <p className="text-sm font-medium">{option.label}</p>
                {"description" in option && (
                  <p className="text-xs text-muted-foreground">{option.description}</p>
                )}
              </div>
              {selected && <Check className="size-4 text-primary" />}
            </Card>
          );
        })}
      </div>
    </div>
  );
}
