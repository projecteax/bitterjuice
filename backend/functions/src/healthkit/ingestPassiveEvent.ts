import { onCall } from "firebase-functions/https";
import { db } from "../firebase.js";
import { assertString, requireAuth } from "../utils/callable.js";
import { applyLedgerMutation } from "../xp/ledger.js";
import { createFeedEvent } from "../feed/events.js";

interface IngestPassiveEventInput {
  squadId?: string;
  eventType: "sleep_8h" | "phone_away_after_18";
  eventValue: number;
  eventAtISO: string;
  idempotencyKey: string;
}

export const ingestPassiveEvent = onCall<IngestPassiveEventInput>(async (request) => {
  const uid = requireAuth(request.auth?.uid);
  const eventType = request.data.eventType;
  const eventValue = Number(request.data.eventValue);
  const eventAtISO = assertString(request.data.eventAtISO, "eventAtISO");
  const idempotencyKey = assertString(request.data.idempotencyKey, "idempotencyKey");
  const squadId = request.data.squadId;

  if (!["sleep_8h", "phone_away_after_18"].includes(eventType)) {
    throw new Error("Invalid eventType.");
  }

  const eventAt = new Date(eventAtISO);
  if (Number.isNaN(eventAt.getTime())) {
    throw new Error("Invalid eventAtISO.");
  }

  const passiveRef = db.collection("passiveEvents").doc();
  await passiveRef.set({
    userId: uid,
    provider: "healthkit",
    eventType,
    eventValue,
    eventAt,
    createdAt: new Date()
  });

  const deltaXp = eventType === "sleep_8h" ? 20 : 15;
  await applyLedgerMutation({
    userId: uid,
    deltaXp,
    reason: "activity",
    refType: "passiveEvent",
    refId: passiveRef.id,
    metadata: {
      eventType,
      eventValue
    },
    idempotencyKey
  });

  if (squadId) {
    await createFeedEvent({
      squadId,
      actorId: uid,
      eventType: "activityLogged",
      objectType: "passiveEvent",
      objectId: passiveRef.id,
      payload: {
        eventType,
        xp: deltaXp
      }
    });
  }

  return { ok: true, passiveEventId: passiveRef.id, awardedXp: deltaXp };
});
