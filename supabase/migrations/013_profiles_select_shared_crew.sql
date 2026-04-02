-- =============================================================================
-- Allow crew members to read each other's public profile (username + avatar_key)
-- =============================================================================
-- Needed for Crew feed to display names/avatars instead of raw UUID.
--
-- We keep profiles UPDATE restricted to self. This only broadens SELECT.
-- =============================================================================

create or replace function public.bitterjuice_share_any_crew (_a uuid, _b uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.squad_members sm1
    join public.squad_members sm2
      on sm2.squad_id = sm1.squad_id
    where sm1.user_id = _a
      and sm2.user_id = _b
  );
$$;

revoke all on function public.bitterjuice_share_any_crew (uuid, uuid) from public;
grant execute on function public.bitterjuice_share_any_crew (uuid, uuid) to authenticated;

drop policy if exists "profiles_select_shared_crew" on public.profiles;

create policy "profiles_select_shared_crew" on public.profiles
for select
using (
  auth.uid () = id
  or public.bitterjuice_share_any_crew (auth.uid (), id)
);

notify pgrst, 'reload schema';

