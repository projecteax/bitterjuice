import { HttpsError } from "firebase-functions/https";

export function requireAuth(uid?: string): string {
  if (!uid) {
    throw new HttpsError("unauthenticated", "User must be authenticated.");
  }
  return uid;
}

export function assertString(value: unknown, field: string): string {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new HttpsError("invalid-argument", `${field} must be a non-empty string.`);
  }
  return value.trim();
}
