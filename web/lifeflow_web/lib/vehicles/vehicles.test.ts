import { describe, expect, it } from "vitest";
import {
  daysUntil,
  formatPlate,
  normalizePlate,
  parseDecimal,
  parseInteger,
  recalcRefueling,
  refuelingTotalMatches,
} from "@/lib/vehicles/format";
import {
  maintenanceSchema,
  refuelingSchema,
  reminderSchema,
  tripSchema,
  vehicleSchema,
} from "@/lib/vehicles/schemas";

describe("parsing", () => {
  it("aceita decimais pt-BR sem arredondar litros", () => {
    expect(parseDecimal("41,234")).toBe(41.234);
    expect(parseDecimal("1.234,567")).toBe(1234.567);
    expect(parseDecimal("5.5")).toBe(5.5);
    expect(parseDecimal("abc")).toBeNull();
    expect(parseDecimal("")).toBeNull();
  });

  it("aceita inteiros com separador de milhar", () => {
    expect(parseInteger("12.345")).toBe(12345);
    expect(parseInteger("0")).toBe(0);
    expect(parseInteger("-1")).toBeNull();
    expect(parseInteger("1,5")).toBeNull();
  });

  it("normaliza e formata placas", () => {
    expect(normalizePlate("abc-1d23")).toBe("ABC1D23");
    expect(formatPlate("ABC1234")).toBe("ABC-1234");
    expect(formatPlate("ABC1D23")).toBe("ABC1D23");
  });

  it("conta dias entre datas de domínio sem fuso", () => {
    expect(daysUntil("2026-03-01", "2026-02-27")).toBe(2);
    expect(daysUntil("2026-02-27", "2026-03-01")).toBe(-2);
    expect(daysUntil("2026-01-01", "2026-01-01")).toBe(0);
  });
});

describe("recalcRefueling", () => {
  it("total = litros × preço ao editar litros ou preço", () => {
    expect(recalcRefueling("liters", { liters: "40", unitPrice: "5,50", total: "" })).toEqual({
      total: "220,00",
    });
    expect(recalcRefueling("unitPrice", { liters: "10,5", unitPrice: "6,00", total: "" })).toEqual({
      total: "63,00",
    });
  });

  it("preço = total ÷ litros ao editar o total", () => {
    expect(recalcRefueling("total", { liters: "40", unitPrice: "", total: "220,00" })).toEqual({
      unitPrice: "5,5000",
    });
  });

  it("editar o total sobrescreve um preço já preenchido", () => {
    expect(recalcRefueling("total", { liters: "40", unitPrice: "1,00", total: "200,00" })).toEqual({
      unitPrice: "5,0000",
    });
  });

  it("não calcula sem dados suficientes", () => {
    expect(recalcRefueling("liters", { liters: "40", unitPrice: "", total: "" })).toEqual({});
    expect(recalcRefueling("total", { liters: "0", unitPrice: "", total: "10" })).toEqual({});
  });

  it("tolera a diferença de 1 centavo da constraint do banco", () => {
    expect(refuelingTotalMatches(40.123, 5.5, 220.68)).toBe(true); // 220,6765 → 220,68
    expect(refuelingTotalMatches(40, 5.5, 220.02)).toBe(false);
    expect(refuelingTotalMatches(40, 5.5, 220.01)).toBe(true);
  });
});

const vehicle = {
  type: "car" as const,
  nickname: "Gol",
  brand: "VW",
  model: "Gol",
  version: "",
  manufactureYear: "",
  modelYear: "",
  licensePlate: "",
  fuelType: "",
  currentOdometer: "0",
  purchaseDate: "",
  purchasePrice: "",
  notes: "",
};

describe("vehicleSchema", () => {
  it("aceita o mínimo", () => {
    expect(vehicleSchema.safeParse(vehicle).success).toBe(true);
  });

  it("valida placa antiga e Mercosul, com ou sem hífen", () => {
    for (const plate of ["ABC1234", "abc-1234", "ABC1D23"]) {
      expect(vehicleSchema.safeParse({ ...vehicle, licensePlate: plate }).success).toBe(true);
    }
    expect(vehicleSchema.safeParse({ ...vehicle, licensePlate: "AB12345" }).success).toBe(false);
  });

  it("ano do modelo deve ser o de fabricação ou o seguinte", () => {
    const ok = vehicleSchema.safeParse({ ...vehicle, manufactureYear: "2020", modelYear: "2021" });
    const bad = vehicleSchema.safeParse({ ...vehicle, manufactureYear: "2020", modelYear: "2022" });
    expect(ok.success).toBe(true);
    expect(bad.success).toBe(false);
  });
});

describe("maintenanceSchema", () => {
  const item = {
    category: "oil",
    description: "Troca de óleo",
    partAmount: "",
    laborAmount: "",
    nextOdometer: "",
    nextDate: "",
  };
  const base = {
    date: "2026-01-10",
    odometer: "10000",
    type: "preventive" as const,
    workshop: "",
    notes: "",
    items: [item],
  };

  it("exige ao menos um item", () => {
    expect(maintenanceSchema.safeParse({ ...base, items: [] }).success).toBe(false);
    expect(maintenanceSchema.safeParse(base).success).toBe(true);
  });

  it("a próxima troca precisa ser posterior (km e data), como no RPC", () => {
    const km = maintenanceSchema.safeParse({ ...base, items: [{ ...item, nextOdometer: "10000" }] });
    const date = maintenanceSchema.safeParse({ ...base, items: [{ ...item, nextDate: "2026-01-10" }] });
    const ok = maintenanceSchema.safeParse({
      ...base,
      items: [{ ...item, nextOdometer: "15000", nextDate: "2026-07-10" }],
    });
    expect(km.success).toBe(false);
    expect(date.success).toBe(false);
    expect(ok.success).toBe(true);
  });
});

describe("refuelingSchema", () => {
  const base = {
    date: "2026-01-10",
    odometer: "10000",
    fuelType: "gasoline",
    liters: "40,000",
    unitPrice: "5,5000",
    total: "220,00",
    fullTank: true,
    gasStation: "",
    notes: "",
  };

  it("valida a conta litros × preço = total", () => {
    expect(refuelingSchema.safeParse(base).success).toBe(true);
    expect(refuelingSchema.safeParse({ ...base, total: "250,00" }).success).toBe(false);
  });
});

describe("reminderSchema", () => {
  it("exige km ou data", () => {
    expect(
      reminderSchema.safeParse({ description: "Óleo", targetOdometer: "", targetDate: "" }).success,
    ).toBe(false);
    expect(
      reminderSchema.safeParse({ description: "Óleo", targetOdometer: "20000", targetDate: "" }).success,
    ).toBe(true);
  });
});

describe("tripSchema", () => {
  const open = { startOdometer: "100", startedAt: "2026-01-10T08:00", purpose: "", endOdometer: "", endedAt: "" };

  it("viagem em andamento não tem fim", () => {
    expect(tripSchema.safeParse(open).success).toBe(true);
  });

  it("fim exige km e horário juntos, sem regredir", () => {
    expect(tripSchema.safeParse({ ...open, endOdometer: "150" }).success).toBe(false);
    expect(
      tripSchema.safeParse({ ...open, endOdometer: "150", endedAt: "2026-01-10T12:00" }).success,
    ).toBe(true);
    expect(
      tripSchema.safeParse({ ...open, endOdometer: "50", endedAt: "2026-01-10T12:00" }).success,
    ).toBe(false);
    expect(
      tripSchema.safeParse({ ...open, endOdometer: "150", endedAt: "2026-01-10T07:00" }).success,
    ).toBe(false);
  });
});
