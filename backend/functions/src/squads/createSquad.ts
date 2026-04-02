import { onCall } from "firebase-functions/https";
import { db } from "../firebase.js";
import { assertString, requireAuth } from "../utils/callable.js";

interface CreateSquadInput {
  name: string;
}

export const createSquad = onCall<CreateSquadInput>(async (request) => {
  const uid = requireAuth(request.auth?.uid);
  const name = assertString(request.data.name, "name");

  const squadRef = db.collection("squads").doc();
  await db.runTransaction(async (tx) => {
    tx.set(squadRef, {
      name,
      ownerId: uid,
      memberCount: 1,
      createdAt: new Date(),
      rulesConfig: {
        vetoThreshold: 2
      }
    });
    tx.set(squadRef.collection("members").doc(uid), {
      role: "owner",
      joinedAt: new Date(),
      status: "active"
    });
  });

  return { ok: true, squadId: squadRef.id };
});
