# BitterJuice — iOS

## Projekt Xcode

Otwórz w Xcode:

**`ios/BitterJuice.xcodeproj`**

Przy pierwszym otwarciu Xcode pobierze **Swift Package** (`firebase-ios-sdk`) — potrzebna jest sieć.

## Konfiguracja

- **Bundle ID:** `com.bitterjuiceapp`.
- **Signing:** w targetze **BitterJuice → Signing & Capabilities** wybierz swój **Team** (Apple Developer), żeby budować na urządzeniu.
- **HealthKit:** jeśli używasz `HealthKitService`, dodaj capability **Health** w Xcode.

## Lokalne testy z emulatorami Firebase

Zobacz [../docs/LOCAL-TESTING-PL.md](../docs/LOCAL-TESTING-PL.md).

## Błąd „NOT FOUND” przy Save profile / callable

Oznacza zwykle, że **Cloud Functions nie są wdrożone** do projektu Firebase (albo region się nie zgadza z `FirebaseFunctionsProvider.region`).

Na Macu:

```bash
cd /ścieżka/do/BitterJuice_0.2/backend/functions
npm install && npm run build
cd ..
firebase deploy --only functions
```

Domyślny region w aplikacji: **`us-central1`** — taki sam jak domyślny deploy. Jeśli w konsoli Functions masz inny region, zmień `FirebaseFunctionsProvider.region` w `FirebaseFunctionsProvider.swift`.
