import { db } from "../firebase.js";

export async function reportServerError(
  where: string,
  error: unknown,
  context?: Record<string, unknown>
): Promise<void> {
  const message = error instanceof Error ? error.message : String(error);
  const stack = error instanceof Error ? error.stack ?? null : null;

  await db.collection("serverErrors").add({
    where,
    message,
    stack,
    context: context ?? {},
    createdAt: new Date()
  });
}
