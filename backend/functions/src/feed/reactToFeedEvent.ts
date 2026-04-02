import { onCall } from "firebase-functions/https";
import { db } from "../firebase.js";
import { assertString, requireAuth } from "../utils/callable.js";

interface ReactToFeedInput {
  feedEventId: string;
  reactionType: "keepItUp" | "proud" | "restABit";
}

export const reactToFeedEvent = onCall<ReactToFeedInput>(async (request) => {
  const uid = requireAuth(request.auth?.uid);
  const feedEventId = assertString(request.data.feedEventId, "feedEventId");
  const reactionType = request.data.reactionType;

  if (!["keepItUp", "proud", "restABit"].includes(reactionType)) {
    throw new Error("Invalid reactionType.");
  }

  const ref = db.collection("feedEvents").doc(feedEventId).collection("reactions").doc(`${uid}_${reactionType}`);
  await ref.set({
    userId: uid,
    type: reactionType,
    createdAt: new Date()
  });

  return { ok: true };
});
