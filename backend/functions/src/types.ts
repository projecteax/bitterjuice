export type GoalType =
  | "overcoming_workaholism"
  | "getting_out_of_slump"
  | "socializing_more"
  | "better_routine"
  | "mental_reset";

export type ActivitySource = "manual" | "healthkit" | "system";

export type ReactionType = "keepItUp" | "proud" | "restABit";

export type BadgeTrackKey = "painter" | "musician" | "writer" | "director" | "athlete";

export type XpReason =
  | "activity"
  | "proof_bonus"
  | "reward_purchase"
  | "veto_freeze"
  | "veto_release"
  | "admin_adjustment";
