-- GRANTs for crew tables (also included at the end of 003_squads.sql).
-- Run this only if you applied an older 003_squads.sql before grants were added.

grant usage on schema public to authenticated;

grant select, insert, update, delete on table public.squads to authenticated;

grant select, insert, update, delete on table public.squad_members to authenticated;
