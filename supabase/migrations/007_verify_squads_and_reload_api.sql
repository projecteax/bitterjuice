-- =============================================================================
-- Run this in Supabase SQL Editor if the app still says:
--   "Could not find the table 'public.squads' in the schema cache"
-- =============================================================================
-- Step A — prove the tables exist in Postgres (should return 2 rows):
select table_schema, table_name
from information_schema.tables
where table_schema = 'public'
  and table_name in ('squads', 'squad_members');

-- Step B — tell PostgREST to reload its schema cache:
NOTIFY pgrst, 'reload schema';

-- Step C — if Step A shows 0 rows, you never applied 003_squads.sql on THIS project.
--          Run supabase/migrations/003_squads.sql first, then run this file again.
--
-- Step D — if Step A returns 2 rows but the app STILL errors:
--   • Dashboard → Project Settings → Data API → ensure schema "public" is exposed.
--   • Dashboard → Project Settings → General → use "Pause project" then resume
--     (forces services to restart; fixes stuck PostgREST on some projects).
--   • Confirm iOS SupabaseConfig.plist URL is this project (not another org/project).
