-- =============================================================================
-- Challenges v2: meaningful goals (sessions / minutes / distance)
-- =============================================================================
-- Backward compatible with 015_challenges.sql by:
-- - adding new columns
-- - backfilling from goal_target
-- =============================================================================

alter table public.challenges
  add column if not exists goal_metric text,
  add column if not exists target_value numeric,
  add column if not exists target_unit text;

-- Normalize existing rows
update public.challenges
set
  goal_metric = coalesce(goal_metric, 'sessions'),
  target_value = coalesce(target_value, goal_target::numeric),
  target_unit = coalesce(target_unit, 'sessions')
where true;

alter table public.challenges
  add constraint challenges_goal_metric_check
    check (goal_metric in ('sessions','minutes','distance'))
    not valid;

alter table public.challenges
  validate constraint challenges_goal_metric_check;

alter table public.challenges
  add constraint challenges_target_value_check
    check (target_value is not null and target_value > 0)
    not valid;

alter table public.challenges
  validate constraint challenges_target_value_check;

-- distance defaults to km
update public.challenges
set target_unit = 'km'
where goal_metric = 'distance' and (target_unit is null or target_unit = '' or target_unit = 'sessions');

create index if not exists challenges_status_idx on public.challenges (status, created_at desc);

notify pgrst, 'reload schema';

