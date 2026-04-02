import { onCall } from "firebase-functions/https";
import { db } from "../firebase.js";
import { calculateXp } from "../xp/rules.js";
import { applyLedgerMutation } from "../xp/ledger.js";
import { createFeedEvent } from "../feed/events.js";
import { categoryToTrack, updateBadgeProgress } from "../badges/progress.js";
import { assertString, requireAuth } from "../utils/callable.js";
import { trackEvent } from "../observability/analytics.js";
import { reportServerError } from "../observability/errors.js";

interface LogActivityInput {
  squadId: string;
  category: "work" | "rest" | "mental" | "physical" | "social" | "survival";
  interestTagId: string;
  durationMinutes: number;
  note?: string;
  proofAssetKey?: string | null;
  lowEnergyMode?: boolean;
  idempotencyKey: string;
}

export const logActivity = onCall<LogActivityInput>(async (request) => {
  try {
    const uid = requireAuth(request.auth?.uid);
    const squadId = assertString(request.data.squadId, "squadId");
    const category = request.data.category;
    const interestTagId = assertString(request.data.interestTagId, "interestTagId");
    const durationMinutes = Number(request.data.durationMinutes);
    const note = request.data.note ?? "";
    const proofAssetKey = request.data.proofAssetKey ?? null;
    const lowEnergyMode = Boolean(request.data.lowEnergyMode);
    const idempotencyKey = assertString(request.data.idempotencyKey, "idempotencyKey");

    if (!["work", "rest", "mental", "physical", "social", "survival"].includes(category)) {
      throw new Error("Invalid category.");
    }
    if (!Number.isFinite(durationMinutes) || durationMinutes <= 0) {
      throw new Error("durationMinutes must be positive.");
    }

    const xp = calculateXp({
      durationMinutes,
      hasProof: Boolean(proofAssetKey),
      lowEnergyMode,
      category
    });

    const activityRef = db.collection("activityLogs").doc();
    await activityRef.set({
      userId: uid,
      squadId,
      category,
      interestTagId,
      durationMinutes,
      source: "manual",
      proofAssetKey,
      note,
      createdAt: new Date(),
      status: "active"
    });

    await applyLedgerMutation({
      userId: uid,
      deltaXp: xp.totalXp,
      reason: "activity",
      refType: "activityLog",
      refId: activityRef.id,
      metadata: {
        baseXp: xp.baseXp,
        proofBonusXp: xp.proofBonusXp,
        lowEnergyBonusXp: xp.lowEnergyBonusXp
      },
      idempotencyKey
    });

    await createFeedEvent({
      squadId,
      actorId: uid,
      eventType: "activityLogged",
      objectType: "activityLog",
      objectId: activityRef.id,
      payload: {
        category,
        durationMinutes,
        xp: xp.totalXp
      }
    });

    const track = categoryToTrack(category);
    if (track) {
      const badgeUpdate = await updateBadgeProgress(uid, track, durationMinutes);
      if (badgeUpdate.leveledUp && badgeUpdate.title) {
        await createFeedEvent({
          squadId,
          actorId: uid,
          eventType: "badgeLevelUp",
          objectType: "badgeTrack",
          objectId: track,
          payload: {
            level: badgeUpdate.level,
            title: badgeUpdate.title
          }
        });
      }
    }

    await trackEvent({
      name: "activity_logged",
      userId: uid,
      properties: { category, durationMinutes, xp: xp.totalXp }
    });

    return {
      ok: true,
      activityLogId: activityRef.id,
      awardedXp: xp.totalXp
    };
  } catch (error) {
    await reportServerError("logActivity", error);
    throw error;
  }
});
