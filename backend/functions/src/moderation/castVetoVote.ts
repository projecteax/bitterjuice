import { onCall } from "firebase-functions/https";
import { db } from "../firebase.js";
import { assertString, requireAuth } from "../utils/callable.js";

interface CastVetoVoteInput {
  caseId: string;
  vote: "veto" | "support";
}

export const castVetoVote = onCall<CastVetoVoteInput>(async (request) => {
  const uid = requireAuth(request.auth?.uid);
  const caseId = assertString(request.data.caseId, "caseId");
  const vote = request.data.vote;

  if (!["veto", "support"].includes(vote)) {
    throw new Error("Invalid vote.");
  }

  const caseRef = db.collection("vetoCases").doc(caseId);
  const voteRef = caseRef.collection("votes").doc(uid);
  await voteRef.set({
    voterId: uid,
    vote,
    createdAt: new Date()
  });

  return { ok: true };
});
