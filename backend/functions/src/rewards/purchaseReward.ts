import { onCall } from "firebase-functions/https";
import { db } from "../firebase.js";
import { applyLedgerMutation } from "../xp/ledger.js";
import { createFeedEvent } from "../feed/events.js";
import { assertString, requireAuth } from "../utils/callable.js";
import { trackEvent } from "../observability/analytics.js";
import { reportServerError } from "../observability/errors.js";

interface PurchaseRewardInput {
  rewardId: string;
  squadId?: string;
  idempotencyKey: string;
}

export const purchaseReward = onCall<PurchaseRewardInput>(async (request) => {
  try {
    const uid = requireAuth(request.auth?.uid);
    const rewardId = assertString(request.data.rewardId, "rewardId");
    const idempotencyKey = assertString(request.data.idempotencyKey, "idempotencyKey");
    const squadId = request.data.squadId;

    const rewardDoc = await db.collection("rewards").doc(rewardId).get();
    if (!rewardDoc.exists) {
      throw new Error("Reward not found.");
    }

    const reward = rewardDoc.data() as { costXp: number; title: string };
    await applyLedgerMutation({
      userId: uid,
      deltaXp: -reward.costXp,
      reason: "reward_purchase",
      refType: "reward",
      refId: rewardId,
      metadata: {
        rewardTitle: reward.title
      },
      idempotencyKey
    });

    const purchaseRef = db.collection("rewardPurchases").doc();
    await purchaseRef.set({
      rewardId,
      buyerId: uid,
      costXp: reward.costXp,
      squadId: squadId ?? null,
      createdAt: new Date()
    });

    if (squadId) {
      await createFeedEvent({
        squadId,
        actorId: uid,
        eventType: "rewardClaimed",
        objectType: "reward",
        objectId: rewardId,
        payload: {
          rewardTitle: reward.title,
          costXp: reward.costXp
        }
      });
    }

    await trackEvent({
      name: "reward_purchased",
      userId: uid,
      properties: { rewardId, costXp: reward.costXp }
    });

    return { ok: true, purchaseId: purchaseRef.id };
  } catch (error) {
    await reportServerError("purchaseReward", error);
    throw error;
  }
});
