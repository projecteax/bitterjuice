# BitterJuice Staging Validation Checklist

## Environment and Security

- Firebase project points to staging namespace.
- Firestore rules deploy succeeds.
- Firestore indexes deploy succeeds.
- R2 credentials are staging-only and scoped.
- Apple Sign In and Google Sign In callback domains are configured.

## Core Product Flows

- New user can create account via email/password.
- New user can complete onboarding with goal + interest tags.
- Daily calibration writes and re-loads correctly.
- Manual activity log produces expected XP for:
  - 30 min -> 10 XP
  - 45 min -> 25 XP
  - 90 min -> 50 XP
- Low-energy survival task applies bonus.
- Activity appears in squad feed.
- Feed reactions persist.
- Reward creation works for user scope.
- Reward purchase deducts correct XP and emits feed event.

## Anti-abuse and Moderation

- Veto vote write works for squad members only.
- Non-members cannot read protected squad data.
- XP cannot be directly changed from client.
- Duplicate activity request with same idempotency key does not double-award XP.

## Integrations

- R2 signed upload URL is issued and expires as expected.
- Proof upload succeeds and key is saved in Firestore.
- HealthKit permission request shows correctly.
- Passive sleep sync sends event and awards XP.

## Observability

- Analytics events are written for onboarding, activity logs, reward purchases.
- Server error reporting creates records on forced failure.
- iOS crash/error events visible in Crashlytics staging project.
