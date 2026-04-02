# Credentials: where everything goes (BitterJuice)

## Co ja (repo) już zrobiłem za Ciebie

- **`GoogleService-Info.plist`** leży w **`ios/BitterJuiceApp/GoogleService-Info.plist`** — to jest właściwe miejsce w kodzie.
- Aplikacja wywołuje **`FirebaseApp.configure()`** przy starcie (`ios/BitterJuiceApp/App/BitterJuiceApp.swift`).

## Czego nie da się zrobić „za Ciebie” bez Twojego konta

Nikt poza Tobą nie może zalogować się do Firebase Console ani Cloudflare i pobrać sekretów. Te dwie rzeczy musisz zrobić **raz** na swoim koncie:

1. Utworzyć projekt Firebase i pobrać `GoogleService-Info.plist`.
2. Utworzyć bucket R2 i wygenerować klucze API (S3-compatible).

## iOS — Firebase (już masz plist)

1. Otwórz projekt w **Xcode**.
2. Przeciągnij **`ios/BitterJuiceApp/GoogleService-Info.plist`** do nawigatora projektu (albo *Add Files…*).
3. Zaznacz **Copy items if needed** (jeśli kopiujesz z innego miejsca) i **Target**: główna aplikacja BitterJuice.
4. W **Build Phases → Copy Bundle Resources** musi być ten plik.
5. Dodaj zależności Firebase przez **Swift Package Manager** (Firebase iOS SDK): minimum **FirebaseAuth**, **FirebaseFirestore**, **FirebaseFunctions**, **FirebaseAnalytics** (opcjonalnie), **FirebaseCrashlytics** (opcjonalnie) — zgodnie z importami w kodzie.

**Bundle ID** w Xcode musi być **identyczny** z tym w Firebase (ten sam, co przy pobraniu plist).

## Backend — Cloudflare R2 (sekrety tylko po stronie serwera)

1. W katalogu `backend/functions` skopiuj szablon:

   ```bash
   cp .env.example .env
   ```

2. Uzupełnij **prawdziwe** wartości w `.env` (plik **nie** commitujemy — jest w `.gitignore`).

3. Kod ładuje `.env` automatycznie przy imporcie `src/index.ts` (`dotenv`).

4. **Co dalej po `.env`:** zobacz [NEXT-STEPS-PL.md](NEXT-STEPS-PL.md) (Firebase CLI, `firebase deploy`, iOS).

5. Przy deployu Functions ustaw te same zmienne w środowisku produkcyjnym (Firebase CLI 12.7+ może brać `.env` z folderu `functions`, inaczej **secrets** w konsoli). Backend czyta je jako `process.env` w runtime.

**Nigdy** nie wkładaj `R2_SECRET_ACCESS_KEY` ani access key do aplikacji iOS ani do `GoogleService-Info.plist`.

## Podsumowanie

| Sekret | Gdzie |
|--------|--------|
| Konfiguracja klienta Firebase (bez „master password”) | `GoogleService-Info.plist` + target Xcode |
| Klucze R2 (tajne) | `backend/functions/.env` lokalnie + secrets na produkcji |

Jeśli coś dalej się nie łączy, najczęstsze przyczyny to: zły Bundle ID, brak dodania plist do targetu, brak pakietów Firebase w SPM, albo puste zmienne R2 na Functions.
