import { onCall } from "firebase-functions/https";
import { db } from "../firebase.js";
import { assertString, requireAuth } from "../utils/callable.js";
import { createFeedEvent } from "./events.js";

interface SendNudgeInput {
  squadId: string;
  toUserId: string;
  message: string;
}

export const sendNudge = onCall<SendNudgeInput>(async (request) => {
  const uid = requireAuth(request.auth?.uid);
  const squadId = assertString(request.data.squadId, "squadId");
  const toUserId = assertString(request.data.toUserId, "toUserId");
  const message = assertString(request.data.message, "message");

  const nudgeRef = db.collection("nudges").doc();
  await nudgeRef.set({
    squadId,
    fromUserId: uid,
    toUserId,
    message,
    createdAt: new Date()
  });

  await createFeedEvent({
    squadId,
    actorId: uid,
    eventType: "nudgeSent",
    objectType: "nudge",
    objectId: nudgeRef.id,
    payload: {
      toUserId
    }
  });

  return { ok: true, nudgeId: nudgeRef.id };
});
