export interface XpRuleInput {
  durationMinutes: number;
  hasProof: boolean;
  lowEnergyMode: boolean;
  category: "work" | "rest" | "mental" | "physical" | "social" | "survival";
}

export interface XpRuleResult {
  baseXp: number;
  proofBonusXp: number;
  lowEnergyBonusXp: number;
  totalXp: number;
}

function baseXpByDuration(durationMinutes: number): number {
  if (durationMinutes <= 30) return 10;
  if (durationMinutes <= 60) return 25;
  return 50;
}

export function calculateXp(input: XpRuleInput): XpRuleResult {
  const baseXp = baseXpByDuration(Math.max(0, input.durationMinutes));
  const proofBonusXp = input.hasProof ? Math.min(5, Math.ceil(baseXp * 0.1)) : 0;
  const lowEnergyBonusXp =
    input.lowEnergyMode && input.category === "survival" ? 8 : 0;

  const totalXp = baseXp + proofBonusXp + lowEnergyBonusXp;

  return {
    baseXp,
    proofBonusXp,
    lowEnergyBonusXp,
    totalXp
  };
}
