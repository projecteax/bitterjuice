-- =============================================================================
-- Verify ALL required BitterJuice tables exist in THIS Supabase project
-- =============================================================================
-- Expected row count: 10

select table_schema, table_name
from information_schema.tables
where table_schema = 'public'
  and table_name in (
    'profiles',
    'user_interest_tags',
    'user_goals',
    'daily_calibrations',
    'rewards',
    'feed_events',
    'feed_reactions',
    'squads',
    'squad_members',
    'activity_logs'
  )
order by table_name;

-- If missing rows:
-- 1) run 001_initial.sql
-- 2) run 002_feed_reactions.sql
-- 3) run 003_squads.sql
-- 4) run 004_activity_logs_reaction_update.sql
-- 5) run 008_all_tables_grants_and_api_reload.sql
