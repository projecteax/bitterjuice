-- =============================================================================
-- Onboarding: multi-select goals per user
-- =============================================================================

create table if not exists public.user_goals (
  user_id uuid not null references auth.users (id) on delete cascade,
  goal_id text not null,
  source text not null default 'onboarding',
  created_at timestamptz not null default now(),
  primary key (user_id, goal_id)
);

alter table public.user_goals enable row level security;

drop policy if exists "user_goals_select_own" on public.user_goals;
drop policy if exists "user_goals_insert_own" on public.user_goals;
drop policy if exists "user_goals_delete_own" on public.user_goals;

create policy "user_goals_select_own" on public.user_goals
for select using (auth.uid () = user_id);

create policy "user_goals_insert_own" on public.user_goals
for insert with check (auth.uid () = user_id);

create policy "user_goals_delete_own" on public.user_goals
for delete using (auth.uid () = user_id);

grant usage on schema public to authenticated;
grant select, insert, delete on table public.user_goals to authenticated;

notify pgrst, 'reload schema';

