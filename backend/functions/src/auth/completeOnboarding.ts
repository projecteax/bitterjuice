import { onCall } from "firebase-functions/https";
import { db } from "../firebase.js";
import { assertString, requireAuth } from "../utils/callable.js";
import { trackEvent } from "../observability/analytics.js";
import { reportServerError } from "../observability/errors.js";

interface CompleteOnboardingInput {
  username: string;
  avatarKey?: string | null;
  primaryGoal: string;
  timezone: string;
  interestTags: string[];
}

export const completeOnboarding = onCall<CompleteOnboardingInput>(async (request) => {
  try {
    const uid = requireAuth(request.auth?.uid);
    const username = assertString(request.data.username, "username");
    const primaryGoal = assertString(request.data.primaryGoal, "primaryGoal");
    const timezone = assertString(request.data.timezone, "timezone");
    const avatarKey = request.data.avatarKey ?? null;
    const interestTags = Array.isArray(request.data.interestTags) ? request.data.interestTags : [];

    if (interestTags.length === 0) {
      throw new Error("interestTags must include at least one tag.");
    }

    const now = new Date();
    const userRef = db.collection("users").doc(uid);

    await db.runTransaction(async (tx) => {
      tx.set(
        userRef,
        {
          username,
          avatarKey,
          primaryGoal,
          timezone,
          onboardingStatus: "complete",
          createdAt: now,
          xpBalance: 0,
          level: 1,
          streakDays: 0,
          lowEnergyDaysCount: 0,
          notificationPrefs: {
            pushEnabled: true,
            remindersEnabled: true
          },
          privacy: {
            discoverableByUsername: true
          },
          themePrefs: {
            reducedMotion: false
          }
        },
        { merge: true }
      );

      for (const tag of interestTags) {
        const tagName = assertString(tag, "interestTag");
        const tagId = tagName.toLowerCase().replace(/[^a-z0-9]+/g, "_").slice(0, 48);
        tx.set(userRef.collection("interestTags").doc(tagId), {
          source: "custom",
          name: tagName,
          createdAt: now
        });
      }
    });

    await trackEvent({
      name: "onboarding_completed",
      userId: uid,
      properties: {
        interestCount: interestTags.length,
        primaryGoal
      }
    });

    return { ok: true };
  } catch (error) {
    await reportServerError("completeOnboarding", error);
    throw error;
  }
});
