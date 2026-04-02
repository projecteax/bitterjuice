-- =============================================================================
-- Challenges MVP (peer-to-peer, optionally within a crew)
-- =============================================================================
-- Features:
-- - creator invites one user (invitee)
-- - statuses: pending / accepted / declined / cancelled / completed
-- - time window: start_at / end_at (can be in the future)
-- - goal is expressed as an activity pick id (matches interest_tag_id choices)
-- - optional prize proposal text + note
--
-- RLS:
-- - only creator and invitee can read
-- - creator can insert and update (cancel / edit while pending)
-- - invitee can update status (accept/decline)
--
-- Feed integration:
-- - later we can add feed_events for challenge_created / accepted / completed
-- =============================================================================

create table if not exists public.challenges (
  id uuid primary key default gen_random_uuid (),
  created_at timestamptz not null default now(),
  created_by uuid not null references auth.users (id) on delete cascade,
  invitee_id uuid not null references auth.users (id) on delete cascade,
  crew_id uuid references public.squads (id) on delete set null,

  status text not null default 'pending'
    check (status in ('pending','accepted','declined','cancelled','completed')),

  activity_pick_id text not null,
  goal_target int not null default 1 check (goal_target >= 1),

  start_at timestamptz not null,
  end_at timestamptz not null,

  prize_proposal text not null default '',
  note text not null default ''
);

create index if not exists challenges_creator_idx on public.challenges (created_by, created_at desc);
create index if not exists challenges_invitee_idx on public.challenges (invitee_id, created_at desc);
create index if not exists challenges_crew_idx on public.challenges (crew_id, created_at desc);

alter table public.challenges enable row level security;

drop policy if exists "challenges_select_participant" on public.challenges;
drop policy if exists "challenges_insert_creator" on public.challenges;
drop policy if exists "challenges_update_creator" on public.challenges;
drop policy if exists "challenges_update_invitee" on public.challenges;

create policy "challenges_select_participant" on public.challenges
for select using (
  auth.uid () = created_by
  or auth.uid () = invitee_id
);

create policy "challenges_insert_creator" on public.challenges
for insert with check (
  auth.uid () = created_by
  and created_by <> invitee_id
  and end_at > start_at
);

-- Creator can cancel (or edit) while still pending, or mark completed later.
create policy "challenges_update_creator" on public.challenges
for update using (auth.uid () = created_by)
with check (auth.uid () = created_by);

-- Invitee can accept/decline (and later confirm completion if you want).
create policy "challenges_update_invitee" on public.challenges
for update using (auth.uid () = invitee_id)
with check (auth.uid () = invitee_id);

grant usage on schema public to authenticated;
grant select, insert, update, delete on table public.challenges to authenticated;

notify pgrst, 'reload schema';

