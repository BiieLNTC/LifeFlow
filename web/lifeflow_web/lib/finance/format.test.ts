import { describe, expect, it } from "vitest";
import {
  addMonths,
  formatDate,
  installmentDates,
  parseMoney,
  shiftMonth,
} from "./format";

describe("parseMoney", () => {
  it("aceita formato brasileiro e ponto decimal", () => {
    expect(parseMoney("1.234,56")).toBe(1234.56);
    expect(parseMoney("1234,5")).toBe(1234.5);
    expect(parseMoney("12.5")).toBe(12.5);
    expect(parseMoney(" 10 ")).toBe(10);
  });
  it("rejeita vazio e lixo", () => {
    expect(parseMoney("")).toBeNull();
    expect(parseMoney("abc")).toBeNull();
    expect(parseMoney("-5")).toBeNull();
    expect(parseMoney("1,2,3")).toBeNull();
  });
});

describe("datas", () => {
  it("formata sem deslocar o dia", () => {
    expect(formatDate("2026-09-01")).toBe("01/09/2026");
  });
  it("addMonths limita ao último dia do mês", () => {
    expect(addMonths("2026-01-31", 1)).toBe("2026-02-28");
    expect(addMonths("2024-01-31", 1)).toBe("2024-02-29");
    expect(addMonths("2026-11-15", 3)).toBe("2027-02-15");
  });
  it("gera parcelas em meses consecutivos", () => {
    expect(installmentDates("2026-10-31", 3)).toEqual([
      "2026-10-31",
      "2026-11-30",
      "2026-12-31",
    ]);
  });
  it("shiftMonth cruza o ano", () => {
    expect(shiftMonth(2026, 1, -1)).toEqual({ year: 2025, month: 12 });
    expect(shiftMonth(2026, 12, 1)).toEqual({ year: 2027, month: 1 });
  });
});
