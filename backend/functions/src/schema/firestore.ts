import type { BadgeTrackKey, ReactionType, XpReason } from "../types.js";

export interface UserDocument {
  username: string;
  avatarKey: string | null;
  primaryGoal: string;
  timezone: string;
  onboardingStatus: "pending" | "complete";
  createdAt: FirebaseFirestore.Timestamp;
  xpBalance: number;
  level: number;
  streakDays: number;
  lowEnergyDaysCount: number;
  notificationPrefs: {
    pushEnabled: boolean;
    remindersEnabled: boolean;
  };
  privacy: {
    discoverableByUsername: boolean;
  };
  themePrefs: {
    reducedMotion: boolean;
  };
}

export interface DailyCalibrationDocument {
  battery: number;
  head: number;
  stress: number;
  lowEnergyMode: boolean;
  generatedTheme: string;
  submittedAt: FirebaseFirestore.Timestamp;
}

export interface ActivityLogDocument {
  userId: string;
  squadId: string;
  category: "work" | "rest" | "mental" | "physical" | "social" | "survival";
  interestTagId: string;
  durationMinutes: number;
  source: "manual" | "healthkit" | "system";
  proofAssetKey: string | null;
  note: string;
  createdAt: FirebaseFirestore.Timestamp;
  status: "active" | "frozen" | "vetoed";
}

export interface XpLedgerDocument {
  userId: string;
  deltaXp: number;
  reason: XpReason;
  refType: string;
  refId: string;
  metadata: Record<string, unknown>;
  createdAt: FirebaseFirestore.Timestamp;
}

export interface BadgeProgressDocument {
  userId: string;
  trackKey: BadgeTrackKey;
  totalMinutes: number;
  sessionCount: number;
  currentLevel: number;
  updatedAt: FirebaseFirestore.Timestamp;
}

export interface FeedEventDocument {
  squadId: string;
  actorId: string;
  eventType: "activityLogged" | "rewardClaimed" | "badgeLevelUp" | "nudgeSent" | "vetoApplied";
  objectType: string;
  objectId: string;
  payload: Record<string, unknown>;
  createdAt: FirebaseFirestore.Timestamp;
}

export interface ReactionDocument {
  userId: string;
  type: ReactionType;
  createdAt: FirebaseFirestore.Timestamp;
}

export interface RewardDocument {
  ownerScope: "user" | "squad";
  ownerId: string;
  title: string;
  description: string;
  costXp: number;
  cooldown: number;
  isActive: boolean;
  createdBy: string;
  createdAt: FirebaseFirestore.Timestamp;
}
