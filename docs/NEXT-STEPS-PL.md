# Co dalej po wrzuceniu `.env` (prosty plan)

Masz już **`backend/functions/.env`** z R2 — o to chodziło po stronie „wpisz sekrety”. Dalej idzie **podłączenie Firebase + wdrożenie**, żeby aplikacja i backend żyły w chmurze, a nie tylko na dysku.

---

## 1. Upewnij się, że `.env` jest we właściwym miejscu

- Ścieżka: **`BitterJuice_0.2/backend/functions/.env`** (obok `package.json` w `functions`, nie w root repozytorium).
- W środku muszą być dokładnie te nazwy (jak w `.env.example`):  
  `R2_ENDPOINT`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_BUCKET`, `R2_PUBLIC_BASE_URL`.

Projekt ładuje ten plik przy starcie funkcji (`import "dotenv/config"` w `src/index.ts`).

---

## 2. Zainstaluj zależności backendu (raz)

W terminalu:

```bash
cd backend/functions
npm install
```

---

## 3. Firebase CLI — żeby „wypchnąć” backend do Twojego projektu Firebase

1. Zainstaluj [Firebase CLI](https://firebase.google.com/docs/cli) (np. `npm install -g firebase-tools`).
2. Zaloguj się: `firebase login`
3. W katalogu **`backend`** (tam jest `firebase.json`) ustaw projekt:

   ```bash
   cd backend
   firebase use --add
   ```

   Wybierz **swój** projekt Firebase (ten sam co `GoogleService-Info.plist` w aplikacji).

4. Wdróż reguły, indeksy i funkcje:

   ```bash
   firebase deploy --only firestore:rules,firestore:indexes,functions
   ```

Po tym **callable functions** (`completeOnboarding`, `logActivity`, `createUploadUrl` itd.) działają w chmurze pod Twoim projektem. Aplikacja iOS woła je przez SDK — musi być ten sam projekt Firebase co w Xcode.

---

## 4. R2 na produkcji (ważne)

- **Lokalnie / emulator:** wystarczy `.env` w `backend/functions`.
- **Po `firebase deploy`:** Firebase musi mieć te same zmienne w środowisku funkcji. Od Firebase CLI **12.7+** plik `.env` w folderze `functions` jest brany pod uwagę przy deployu — jeśli używasz starszego CLI, ustaw zmienne ręcznie (np. [parametry / secrets w dokumentacji Functions](https://firebase.google.com/docs/functions/config-env)).

Jeśli po deployu `createUploadUrl` krzyczy o braku `R2_*`, znaczy że zmienne nie trafiły do środowiska produkcyjnego — wtedy dopinasz je w konsoli Firebase albo przez `firebase functions:secrets:set` / pliki `.env` zgodnie z dokumentacją.

---

## 5. Aplikacja iOS (żeby w ogóle gadała z Firebase)

1. Otwórz projekt w **Xcode** (swój `.xcodeproj` / `.xcworkspace`).
2. **`GoogleService-Info.plist`** w targetcie aplikacji (np. `ios/BitterJuiceApp/GoogleService-Info.plist`).
3. Dodaj pakiety **Firebase** (SPM): Auth, Firestore, Functions itd.
4. **Bundle ID** = jak w Firebase.

Bez tego sam `.env` na backendzie nie sprawi, że iOS „magicznie” się połączy.

---

## Podsumowanie w jednym zdaniu

**`.env`** = sekrety R2 dla kodu funkcji. **Kolejne kroki** = `npm install` w `functions`, potem **`firebase deploy`** z katalogu `backend`, potem dopięcie **iOS + ten sam projekt Firebase**.

Jeśli napiszesz, czy już masz **`firebase login`** i czy deploy przechodzi (albo jaki jest błąd), można rozwinąć dokładnie ten jeden krok, który u Ciebie się wywalił.
