-- =============================================================================
-- Fix: infinite recursion detected in policy for relation 'squad_members'
-- =============================================================================
-- Cause: SELECT policies used EXISTS (subquery on squad_members), which
-- re-evaluated RLS on the same table → recursion.
--
-- Fix: SECURITY DEFINER helper reads squad_members as owner (bypasses RLS).
-- Run in SQL Editor on the project used by the iOS app. Safe to re-run.
-- =============================================================================

create or replace function public.bitterjuice_auth_uid_in_squad (_squad_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.squad_members sm
    where sm.squad_id = _squad_id
      and sm.user_id = (select auth.uid ())
  );
$$;

revoke all on function public.bitterjuice_auth_uid_in_squad (uuid) from public;

grant execute on function public.bitterjuice_auth_uid_in_squad (uuid) to authenticated;

drop policy if exists "squads_select_member_or_creator" on public.squads;

create policy "squads_select_member_or_creator" on public.squads for select using (
  created_by = auth.uid ()
  or public.bitterjuice_auth_uid_in_squad (id)
);

drop policy if exists "squad_members_select" on public.squad_members;

create policy "squad_members_select" on public.squad_members for select using (
  user_id = auth.uid ()
  or public.bitterjuice_auth_uid_in_squad (squad_id)
);

notify pgrst, 'reload schema';
