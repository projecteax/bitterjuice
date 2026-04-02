import { db } from "../firebase.js";
import type { BadgeTrackKey } from "../types.js";

const badgeThresholds: Record<BadgeTrackKey, Array<{ level: number; minutes: number; title: string }>> = {
  painter: [
    { level: 1, minutes: 120, title: "Bob Ross" },
    { level: 2, minutes: 600, title: "Van Gogh" },
    { level: 3, minutes: 1800, title: "Picasso" }
  ],
  musician: [
    { level: 1, minutes: 120, title: "Chopin" },
    { level: 2, minutes: 600, title: "Beethoven" },
    { level: 3, minutes: 1800, title: "Mozart" }
  ],
  writer: [
    { level: 1, minutes: 120, title: "Poe" },
    { level: 2, minutes: 600, title: "Tolkien" },
    { level: 3, minutes: 1800, title: "Shakespeare" }
  ],
  director: [
    { level: 1, minutes: 120, title: "Tarantino" },
    { level: 2, minutes: 600, title: "Kubrick" },
    { level: 3, minutes: 1800, title: "Spielberg" }
  ],
  athlete: [
    { level: 1, minutes: 120, title: "Bolt" },
    { level: 2, minutes: 600, title: "Jordan" },
    { level: 3, minutes: 1800, title: "Ali" }
  ]
};

export function categoryToTrack(category: string): BadgeTrackKey | null {
  if (category === "physical") return "athlete";
  if (category === "mental") return "writer";
  if (category === "social") return "director";
  if (category === "rest") return "musician";
  if (category === "work") return "painter";
  return null;
}

export async function updateBadgeProgress(
  userId: string,
  trackKey: BadgeTrackKey,
  durationMinutes: number
): Promise<{ leveledUp: boolean; level: number; title?: string }> {
  const progressId = `${userId}_${trackKey}`;
  const progressRef = db.collection("badgeProgress").doc(progressId);

  return db.runTransaction(async (tx) => {
    const now = new Date();
    const doc = await tx.get(progressRef);
    const currentMinutes = Number(doc.data()?.totalMinutes ?? 0);
    const currentSessions = Number(doc.data()?.sessionCount ?? 0);
    const currentLevel = Number(doc.data()?.currentLevel ?? 0);
    const totalMinutes = currentMinutes + durationMinutes;
    const sessionCount = currentSessions + 1;

    const thresholds = badgeThresholds[trackKey];
    const achieved = thresholds.filter((item) => totalMinutes >= item.minutes);
    const newLevel = achieved.length > 0 ? achieved[achieved.length - 1].level : currentLevel;
    const leveledUp = newLevel > currentLevel;

    tx.set(
      progressRef,
      {
        userId,
        trackKey,
        totalMinutes,
        sessionCount,
        currentLevel: Math.max(currentLevel, newLevel),
        updatedAt: now
      },
      { merge: true }
    );

    if (leveledUp) {
      const levelEntry = achieved[achieved.length - 1];
      tx.set(db.collection("badgeAwards").doc(), {
        userId,
        trackKey,
        level: levelEntry.level,
        title: levelEntry.title,
        awardedAt: now
      });
      return { leveledUp: true, level: levelEntry.level, title: levelEntry.title };
    }

    return { leveledUp: false, level: Math.max(currentLevel, newLevel) };
  });
}
