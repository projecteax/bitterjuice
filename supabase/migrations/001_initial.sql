-- BitterJuice — schemat startowy (Supabase Postgres)
-- Uruchom w: Supabase Dashboard → SQL Editor → wklej → Run
-- Albo: supabase db push (jeśli używasz Supabase CLI)
--
-- Safe to re-run: policies are dropped first (avoids "policy already exists").

-- Profil użytkownika (1:1 z auth.users)
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  username text not null,
  avatar_key text,
  primary_goal text not null,
  timezone text not null default 'UTC',
  onboarding_status text not null default 'pending' check (onboarding_status in ('pending', 'complete')),
  xp_balance int not null default 0,
  level int not null default 1,
  streak_days int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.user_interest_tags (
  id uuid primary key default gen_random_uuid (),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  source text not null default 'custom',
  created_at timestamptz not null default now(),
  unique (user_id, name)
);

-- Kalibracja dziennika (nastrój)
create table if not exists public.daily_calibrations (
  user_id uuid not null references auth.users (id) on delete cascade,
  date_key date not null,
  battery real not null,
  head real not null,
  stress real not null,
  low_energy boolean not null default false,
  generated_theme text default 'auto',
  submitted_at timestamptz not null default now(),
  primary key (user_id, date_key)
);

-- Nagrody (MVP — proste kolumny)
create table if not exists public.rewards (
  id uuid primary key default gen_random_uuid (),
  owner_scope text not null check (owner_scope in ('user', 'squad')),
  owner_id text not null,
  title text not null,
  description text not null default '',
  cost_xp int not null,
  is_active boolean not null default true,
  created_by uuid references auth.users (id),
  created_at timestamptz not null default now()
);

-- Feed (opcjonalnie na później)
create table if not exists public.feed_events (
  id uuid primary key default gen_random_uuid (),
  squad_id uuid not null,
  actor_id uuid not null references auth.users (id),
  event_type text not null,
  object_type text,
  object_id text,
  payload jsonb default '{}',
  created_at timestamptz not null default now()
);

-- RLS
alter table public.profiles enable row level security;
alter table public.user_interest_tags enable row level security;
alter table public.daily_calibrations enable row level security;
alter table public.rewards enable row level security;
alter table public.feed_events enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
drop policy if exists "profiles_insert_own" on public.profiles;
drop policy if exists "profiles_update_own" on public.profiles;

drop policy if exists "tags_select_own" on public.user_interest_tags;
drop policy if exists "tags_insert_own" on public.user_interest_tags;
drop policy if exists "tags_delete_own" on public.user_interest_tags;

drop policy if exists "calib_select_own" on public.daily_calibrations;
drop policy if exists "calib_insert_own" on public.daily_calibrations;
drop policy if exists "calib_update_own" on public.daily_calibrations;

drop policy if exists "rewards_select" on public.rewards;
drop policy if exists "rewards_insert_own" on public.rewards;

drop policy if exists "feed_select_squad" on public.feed_events;
drop policy if exists "feed_insert_own" on public.feed_events;

create policy "profiles_select_own" on public.profiles for select using (auth.uid () = id);
create policy "profiles_insert_own" on public.profiles for insert with check (auth.uid () = id);
create policy "profiles_update_own" on public.profiles for update using (auth.uid () = id);

create policy "tags_select_own" on public.user_interest_tags for select using (auth.uid () = user_id);
create policy "tags_insert_own" on public.user_interest_tags for insert with check (auth.uid () = user_id);
create policy "tags_delete_own" on public.user_interest_tags for delete using (auth.uid () = user_id);

create policy "calib_select_own" on public.daily_calibrations for select using (auth.uid () = user_id);
create policy "calib_insert_own" on public.daily_calibrations for insert with check (auth.uid () = user_id);
create policy "calib_update_own" on public.daily_calibrations for update using (auth.uid () = user_id);

create policy "rewards_select" on public.rewards for select using (
  (owner_scope = 'user' and owner_id = auth.uid ()::text)
  or owner_scope = 'squad'
);
create policy "rewards_insert_own" on public.rewards for insert with check (
  auth.uid () = created_by
);

create policy "feed_select_squad" on public.feed_events for select using (true);
create policy "feed_insert_own" on public.feed_events for insert with check (auth.uid () = actor_id);
