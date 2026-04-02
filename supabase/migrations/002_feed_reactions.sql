-- Reakcje do wpisów w feedzie (proud / keepItUp / restABit)
-- Uruchom w Supabase SQL Editor po 001_initial.sql
-- Safe to re-run (policies dropped first).

create table if not exists public.feed_reactions (
  id uuid primary key default gen_random_uuid (),
  feed_event_id uuid not null references public.feed_events (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  reaction_type text not null check (
    reaction_type in ('proud', 'keepItUp', 'restABit')
  ),
  created_at timestamptz not null default now (),
  unique (feed_event_id, user_id, reaction_type)
);

create index if not exists feed_reactions_event_idx on public.feed_reactions (feed_event_id);

alter table public.feed_reactions enable row level security;

drop policy if exists "feed_reactions_select" on public.feed_reactions;
drop policy if exists "feed_reactions_insert_own" on public.feed_reactions;
drop policy if exists "feed_reactions_delete_own" on public.feed_reactions;

create policy "feed_reactions_select" on public.feed_reactions for select using (true);

create policy "feed_reactions_insert_own" on public.feed_reactions for insert with check (auth.uid () = user_id);

create policy "feed_reactions_delete_own" on public.feed_reactions for delete using (auth.uid () = user_id);
