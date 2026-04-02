import { db } from "../firebase.js";
import type { XpReason } from "../types.js";

interface LedgerMutationInput {
  userId: string;
  deltaXp: number;
  reason: XpReason;
  refType: string;
  refId: string;
  metadata?: Record<string, unknown>;
  idempotencyKey: string;
}

export async function applyLedgerMutation(input: LedgerMutationInput): Promise<void> {
  const userRef = db.collection("users").doc(input.userId);
  const ledgerRef = db.collection("xpLedger").doc();
  const idempotencyRef = db.collection("idempotencyKeys").doc(input.idempotencyKey);

  await db.runTransaction(async (tx) => {
    const idempotencyDoc = await tx.get(idempotencyRef);
    if (idempotencyDoc.exists) {
      return;
    }

    const userDoc = await tx.get(userRef);
    const currentXp = Number(userDoc.data()?.xpBalance ?? 0);
    const nextXp = currentXp + input.deltaXp;

    if (nextXp < 0) {
      throw new Error("Insufficient XP balance.");
    }

    tx.set(ledgerRef, {
      userId: input.userId,
      deltaXp: input.deltaXp,
      reason: input.reason,
      refType: input.refType,
      refId: input.refId,
      metadata: input.metadata ?? {},
      createdAt: new Date()
    });

    tx.set(
      userRef,
      {
        xpBalance: nextXp
      },
      { merge: true }
    );

    tx.set(idempotencyRef, {
      userId: input.userId,
      refType: input.refType,
      refId: input.refId,
      createdAt: new Date()
    });
  });
}
