-- =============================================================================
-- Storage: avatars bucket for profile pictures
-- =============================================================================
-- Creates a public-read avatars bucket and allows authenticated users to upload
-- and manage only their own objects under `<uid>/...`.
--
-- Note: Storage schema is `storage`. This is standard in Supabase projects.
-- =============================================================================

-- Bucket (id == name)
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do update set public = excluded.public;

-- Objects RLS policies
drop policy if exists "avatars_select_public" on storage.objects;
drop policy if exists "avatars_insert_own" on storage.objects;
drop policy if exists "avatars_update_own" on storage.objects;
drop policy if exists "avatars_delete_own" on storage.objects;

-- Public read (bucket is public; keep explicit policy for clarity)
create policy "avatars_select_public"
on storage.objects for select
using (bucket_id = 'avatars');

-- Only allow writes to own prefix: `<uid>/...`
create policy "avatars_insert_own"
on storage.objects for insert
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid ()::text
);

create policy "avatars_update_own"
on storage.objects for update
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid ()::text
)
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid ()::text
);

create policy "avatars_delete_own"
on storage.objects for delete
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid ()::text
);

