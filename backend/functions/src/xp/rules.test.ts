import { describe, expect, it } from "vitest";
import { calculateXp } from "./rules.js";

describe("calculateXp", () => {
  it("applies 10 xp for up to 30 minutes", () => {
    const result = calculateXp({
      durationMinutes: 30,
      hasProof: false,
      lowEnergyMode: false,
      category: "work"
    });
    expect(result.totalXp).toBe(10);
  });

  it("applies 25 xp for 31-60 minutes", () => {
    const result = calculateXp({
      durationMinutes: 45,
      hasProof: false,
      lowEnergyMode: false,
      category: "work"
    });
    expect(result.totalXp).toBe(25);
  });

  it("caps base xp at 50 for long sessions", () => {
    const result = calculateXp({
      durationMinutes: 200,
      hasProof: false,
      lowEnergyMode: false,
      category: "work"
    });
    expect(result.baseXp).toBe(50);
  });

  it("applies proof and low-energy survival bonuses", () => {
    const result = calculateXp({
      durationMinutes: 30,
      hasProof: true,
      lowEnergyMode: true,
      category: "survival"
    });
    expect(result.totalXp).toBe(19);
  });
});
