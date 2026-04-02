import { db } from "../firebase.js";

export async function createFeedEvent(input: {
  squadId: string;
  actorId: string;
  eventType: "activityLogged" | "rewardClaimed" | "badgeLevelUp" | "nudgeSent" | "vetoApplied";
  objectType: string;
  objectId: string;
  payload?: Record<string, unknown>;
}): Promise<string> {
  const ref = db.collection("feedEvents").doc();
  await ref.set({
    squadId: input.squadId,
    actorId: input.actorId,
    eventType: input.eventType,
    objectType: input.objectType,
    objectId: input.objectId,
    payload: input.payload ?? {},
    createdAt: new Date()
  });
  return ref.id;
}
