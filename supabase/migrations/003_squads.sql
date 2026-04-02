-- =============================================================================
-- Juice Crews — REQUIRED for the iOS "Create crew" / join / feed by crew id flow.
-- =============================================================================
-- If the app says: "could not find the table public.squads" → this file was
-- never applied to your Supabase project.
--
-- How to apply:
--   1. Open https://supabase.com/dashboard → your project
--   2. SQL Editor → New query
--   3. Paste this entire file → Run
--
-- Order: run 001_initial.sql first (profiles, feed_events, etc.). 002 is optional
-- (reactions). This file is safe to re-run (policies are dropped then recreated).
-- =============================================================================

create table if not exists public.squads (
  id uuid primary key default gen_random_uuid (),
  name text not null,
  created_by uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now ()
);

create table if not exists public.squad_members (
  squad_id uuid not null references public.squads (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  role text not null default 'member' check (role in ('owner', 'member')),
  joined_at timestamptz not null default now (),
  primary key (squad_id, user_id)
);

create index if not exists squad_members_user_idx on public.squad_members (user_id);

alter table public.squads enable row level security;
alter table public.squad_members enable row level security;

-- No EXISTS (select … from squad_members) inside squad_members/squads SELECT policies — that causes infinite RLS recursion.
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
drop policy if exists "squads_insert_creator" on public.squads;

create policy "squads_select_member_or_creator" on public.squads for select using (
  created_by = auth.uid ()
  or public.bitterjuice_auth_uid_in_squad (id)
);

create policy "squads_insert_creator" on public.squads for insert with check (auth.uid () = created_by);

drop policy if exists "squad_members_select" on public.squad_members;
drop policy if exists "squad_members_insert_self" on public.squad_members;

create policy "squad_members_select" on public.squad_members for select using (
  user_id = auth.uid ()
  or public.bitterjuice_auth_uid_in_squad (squad_id)
);

create policy "squad_members_insert_self" on public.squad_members for insert with check (auth.uid () = user_id);

-- PostgREST uses role "authenticated" for signed-in users. Tables need explicit GRANTs.
grant usage on schema public to authenticated;

grant select, insert, update, delete on table public.squads to authenticated;

grant select, insert, update, delete on table public.squad_members to authenticated;

-- PostgREST keeps a schema cache. Without this, new tables can exist in Postgres but REST still
-- returns: "Could not find the table 'public.squads' in the schema cache"
NOTIFY pgrst, 'reload schema';
