# Testowanie lokalnie (bez deploya)

Masz: **`.env`** w `backend/functions/` + kod. Żeby to **przetestować lokalnie**, odpalasz **Firebase Emulator Suite** na Macu — to udaje Auth, Firestore i Cloud Functions na Twoim komputerze.

**Domyślnie aplikacja łączy się z prawdziwym Firebase w chmurze** (żeby nie było błędu „Connection refused” na `127.0.0.1`).

Żeby iOS używał emulatorów, musisz **jednocześnie**:

1. Uruchomić `firebase emulators:start` w katalogu `backend`.
2. W Xcode: **Product → Scheme → Edit Scheme → Run → Arguments → Arguments Passed On Launch** dodać:  
   `-useFirebaseEmulators`

---

## 1. Jednorazowo: Firebase CLI

```bash
npm install -g firebase-tools
firebase login
```

W katalogu `backend` ustaw projekt (może być ten sam co w konsoli — emulatory i tak działają lokalnie):

```bash
cd backend
firebase use <twoj-project-id>
```

---

## 2. Zainstaluj zależności i zbuduj funkcje

```bash
cd backend/functions
npm install
npm run build
```

---

## 3. Uruchom emulatory

Z katalogu **`backend`** (tam jest `firebase.json`):

```bash
cd backend
firebase emulators:start
```

Zostaw ten terminal włączony. W przeglądarce otworzy się (lub wejdź ręcznie) **Emulator UI**, zwykle: http://127.0.0.1:4000 — tam widać Auth, Firestore, logi funkcji.

Porty (domyślne w tym repo):

| Usługa    | Port |
|-----------|------|
| Auth      | 9099 |
| Firestore | 8080 |
| Functions | 5001 |
| UI        | 4000 |

---

## 4. Aplikacja iOS

1. Otwórz projekt w **Xcode**.
2. Uruchom appkę na **symulatorze iPhone** (do `127.0.0.1` pasuje od razu).
3. Kod w `FirebaseEmulators.connectForLocalTesting()` jest włączony tylko w **`#if DEBUG`** — łączy Auth / Firestore / Functions z emulatorem.

**Fizyczny iPhone:** `127.0.0.1` to nie Twój Mac — wtedy w `FirebaseEmulators.swift` zmień `host` na **adres LAN Maca** (np. `192.168.0.15`), Mac i telefon w tej samej sieci Wi‑Fi.

---

## 5. R2 (Cloudflare) przy emulatorze

Funkcje `createUploadUrl` itd. czytają **`backend/functions/.env`** przez `dotenv`. Gdy emulator odpala funkcje lokalnie, te zmienne **powinny działać**, o ile `.env` jest poprawny.

Jeśli coś nie działa, sprawdź w Emulator UI log błędu przy wywołaniu funkcji (często brak zmiennej lub zły endpoint).

---

## 6. Kiedy wrócić na „prawdziwy” Firebase w chmurze

- Zatrzymaj emulatory (`Ctrl+C` w terminalu).
- W `BitterJuiceApp.swift` **usuń lub zakomentuj** linię `FirebaseEmulators.connectForLocalTesting()` (albo ustaw flagę kompilacji), żeby appka nie szła na `127.0.0.1`.
- Wtedy potrzebny jest normalny **deploy** funkcji i reguł do projektu w chmurze.

---

## Krótkie podsumowanie

| Krok | Co robisz |
|------|-----------|
| 1 | `firebase emulators:start` w `backend` |
| 2 | Xcode → Run na symulatorze (Debug) |
| 3 | Testuj logowanie / Firestore / callable functions |

To jest standardowy sposób: **bez deploya**, wszystko lokalnie.
