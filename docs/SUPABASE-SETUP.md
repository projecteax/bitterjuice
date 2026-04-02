# Supabase — konfiguracja krok po kroku (BitterJuice)

## Krok 1: Konto i projekt

1. Wejdź na [https://supabase.com](https://supabase.com) → **Zaloguj się** (GitHub lub Google).
2. **New project** → wybierz organizację, **nazwa** (np. `bitterjuice`), **hasło do bazy** (zapisz w menedżerze haseł).
3. **Region** — wybierz najbliższy (np. Frankfurt).
4. Poczekaj aż projekt się utworzy (~2 min).

## Krok 2: Klucze API (do aplikacji iOS)

1. W projekcie: **Project Settings** (ikona zębatki) → **API**.
2. Skopiuj:
   - **Project URL** (np. `https://abcdefgh.supabase.co`)
   - **anon public** key (długi łańcuch zaczynający się od `eyJ...`)

## Krok 3: Plik konfiguracyjny w Xcode

1. W repozytorium jest szablon: `ios/BitterJuiceApp/SupabaseConfig.plist`.
2. Otwórz go w edytorze i wklej **własne** wartości zamiast `REPLACE_ME`:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
3. W Xcode upewnij się, że plik jest w **targetcie** BitterJuice (Build Phases → Copy Bundle Resources).

**Uwaga:** `anon` key jest w aplikacji — to normalne; bezpieczeństwo daje **RLS** w bazie. Nie wklejaj **service_role** do aplikacji.

## Krok 4: Baza danych (tabele + RLS)

1. W Supabase: **SQL Editor** → **New query**.
2. Wklej całą zawartość pliku [`supabase/migrations/001_initial.sql`](../supabase/migrations/001_initial.sql).
3. Kliknij **Run**. Powinno być bez błędów.

## Krok 5: Logowanie e-mailem

1. **Authentication** → **Providers** → **Email**.
2. Dla developmentu możesz włączyć:
   - **Confirm email** = OFF (żeby od razu działało zakładanie konta bez linku z maila).
3. Zapisz.

## Krok 6: Build iOS

1. Otwórz `ios/BitterJuice.xcodeproj`.
2. **File → Packages → Resolve Package Versions** (pobierze `supabase-swift`).
3. Uruchom aplikację na symulatorze.

## Co dalej (opcjonalnie)

- **Apple / Google Sign-In** — osobna konfiguracja w Supabase Auth + iOS.
- **Edge Functions** — jeśli chcesz logikę XP po stronie serwera (zamiast samego klienta).
- **R2** — możesz nadal używać do plików; upload przez Edge Function lub podpisany URL.

## Problemy

| Objaw | Co sprawdzić |
|--------|----------------|
| Crash przy starcie „SupabaseConfig” | Wypełnij plist, plik w targetcie. |
| „Invalid login” | Email provider włączony; hasło min. 6 znaków. |
| RLS / permission denied | Czy uruchomiłeś `001_initial.sql`? |
