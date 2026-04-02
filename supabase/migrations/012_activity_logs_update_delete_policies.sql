-- =============================================================================
-- Allow users to edit/delete their own activity logs (Log history UX)
-- =============================================================================

alter table public.activity_logs enable row level security;

drop policy if exists "activity_logs_update_own" on public.activity_logs;
drop policy if exists "activity_logs_delete_own" on public.activity_logs;

create policy "activity_logs_update_own" on public.activity_logs
  for update
  using (auth.uid () = user_id)
  with check (auth.uid () = user_id);

create policy "activity_logs_delete_own" on public.activity_logs
  for delete
  using (auth.uid () = user_id);

grant select, insert, update, delete on table public.activity_logs to authenticated;

notify pgrst, 'reload schema';

