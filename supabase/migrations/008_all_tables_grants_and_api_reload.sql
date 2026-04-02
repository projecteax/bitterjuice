-- =============================================================================
-- BitterJuice runtime grants for ALL app tables + PostgREST schema reload
-- =============================================================================
-- Run this on the same Supabase project used by iOS SupabaseConfig.plist.
-- Safe to re-run.

grant usage on schema public to authenticated;

grant select, insert, update, delete on table public.profiles to authenticated;
grant select, insert, update, delete on table public.user_interest_tags to authenticated;
grant select, insert, update, delete on table public.daily_calibrations to authenticated;
grant select, insert, update, delete on table public.rewards to authenticated;
grant select, insert, update, delete on table public.feed_events to authenticated;
grant select, insert, update, delete on table public.feed_reactions to authenticated;
grant select, insert, update, delete on table public.squads to authenticated;
grant select, insert, update, delete on table public.squad_members to authenticated;
grant select, insert, update, delete on table public.activity_logs to authenticated;

-- Refresh PostgREST OpenAPI/schema cache.
NOTIFY pgrst, 'reload schema';
