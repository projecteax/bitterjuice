import { db } from "../firebase.js";

interface AnalyticsEventInput {
  name: string;
  userId?: string;
  properties?: Record<string, unknown>;
}

export async function trackEvent(input: AnalyticsEventInput): Promise<void> {
  await db.collection("analyticsEvents").add({
    name: input.name,
    userId: input.userId ?? null,
    properties: input.properties ?? {},
    createdAt: new Date()
  });
}
