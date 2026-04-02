# BitterJuice

Production-grade iPhone app focused on anti-hustle gamification, social accountability, and meaningful progress loops.

## Tech Stack

- iOS app: SwiftUI
- Auth: Firebase Auth (Apple, Google, email/password)
- App DB: Firestore
- Server logic: Firebase Functions (TypeScript)
- Media storage: Cloudflare R2

## Monorepo Layout

- `ios/BitterJuice.xcodeproj`: **otwórz ten plik w Xcode** (projekt aplikacji)
- `ios/BitterJuiceApp`: kod źródłowy Swift
- `backend/functions`: server-side logic
- `backend/firestore.rules`: Firestore authorization rules
- `backend/firestore.indexes.json`: query indexes
- `docs/performance-budgets.md`: latency and reliability budgets
- `docs/staging-validation-checklist.md`: production validation checklist
- `docs/LOCAL-TESTING-PL.md`: testy lokalne bez deploya (Firebase Emulator + iOS)

## Local Setup

1. **Credentials (Firebase + R2):** follow [docs/SETUP-CREDENTIALS.md](docs/SETUP-CREDENTIALS.md). The iOS plist lives at `ios/BitterJuiceApp/GoogleService-Info.plist`; add it to your Xcode target and install Firebase via SPM.
2. Install Node.js 20+.
3. Run `npm install` inside `backend/functions`.
4. Copy `backend/functions/.env.example` to `backend/functions/.env` and fill R2 variables:
   - `R2_ENDPOINT`
   - `R2_ACCESS_KEY_ID`
   - `R2_SECRET_ACCESS_KEY`
   - `R2_BUCKET`
   - `R2_PUBLIC_BASE_URL`
5. Attach Firebase project and deploy rules/indexes/functions through Firebase CLI.

## Quality Gates

- Run `npm test` in `backend/functions` for XP rules coverage.
- Validate staging with `docs/staging-validation-checklist.md`.
- Track runtime budgets in `docs/performance-budgets.md`.
