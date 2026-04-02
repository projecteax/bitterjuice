import { onCall } from "firebase-functions/https";
import { db } from "../firebase.js";
import { assertString, requireAuth } from "../utils/callable.js";

interface CreateRewardInput {
  ownerScope: "user" | "squad";
  ownerId: string;
  title: string;
  description: string;
  costXp: number;
  cooldown?: number;
}

export const createReward = onCall<CreateRewardInput>(async (request) => {
  const uid = requireAuth(request.auth?.uid);
  const ownerScope = request.data.ownerScope;
  const ownerId = assertString(request.data.ownerId, "ownerId");
  const title = assertString(request.data.title, "title");
  const description = assertString(request.data.description, "description");
  const costXp = Number(request.data.costXp);
  const cooldown = Number(request.data.cooldown ?? 0);

  if (!["user", "squad"].includes(ownerScope)) {
    throw new Error("Invalid ownerScope.");
  }
  if (!Number.isFinite(costXp) || costXp <= 0) {
    throw new Error("costXp must be positive.");
  }

  const rewardRef = db.collection("rewards").doc();
  await rewardRef.set({
    ownerScope,
    ownerId,
    title,
    description,
    costXp,
    cooldown,
    isActive: true,
    createdBy: uid,
    createdAt: new Date()
  });

  return { ok: true, rewardId: rewardRef.id };
});
