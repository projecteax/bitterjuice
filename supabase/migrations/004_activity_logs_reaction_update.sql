-- Fix feed_reactions upsert: PostgREST merge-duplicates runs ON CONFLICT DO UPDATE,
-- which requires an UPDATE policy (INSERT alone is not enough).
drop policy if exists "feed_reactions_update_own" on public.feed_reactions;

create policy "feed_reactions_update_own" on public.feed_reactions
  for update
  using (auth.uid () = user_id)
  with check (auth.uid () = user_id);

-- Personal activity history (always saved from the app, independent of crew feed).
create table if not exists public.activity_logs (
  id uuid primary key default gen_random_uuid (),
  user_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now (),
  category text not null,
  interest_tag_id text not null,
  duration_minutes int not null,
  note text not null default '',
  low_energy boolean not null default false,
  proof_asset_key text,
  posted_to_squad_feed boolean not null default false,
  squad_id uuid
);

create index if not exists activity_logs_user_created_idx on public.activity_logs (user_id, created_at desc);

alter table public.activity_logs enable row level security;

drop policy if exists "activity_logs_select_own" on public.activity_logs;
drop policy if exists "activity_logs_insert_own" on public.activity_logs;

create policy "activity_logs_select_own" on public.activity_logs for select using (auth.uid () = user_id);

create policy "activity_logs_insert_own" on public.activity_logs for insert with check (auth.uid () = user_id);
