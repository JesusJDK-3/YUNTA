create table if not exists public.post_images (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null unique references public.posts(id) on delete cascade,
  author_id uuid not null references auth.users(id) on delete cascade,
  storage_path text not null unique,
  created_at timestamptz not null default now(),
  check (storage_path ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.(jpg|jpeg|png|webp)$')
);

create or replace function public.can_view_post_image(p_post_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1
    from public.posts p
    left join public.private_profiles me on me.user_id = auth.uid()
    where p.id = p_post_id
      and (
        p.author_id = auth.uid()
        or public.can_access_post(p.id)
        or (
          p.status in ('open', 'coordinating')
          and me.user_id is not null
          and extensions.st_dwithin(
            p.location,
            extensions.st_setsrid(
              extensions.st_makepoint(me.longitude, me.latitude), 4326
            )::extensions.geography,
            500
          )
        )
      )
  );
$$;

create or replace function public.can_upload_post_image(
  p_storage_path text, p_post_id uuid
)
returns boolean language sql stable security definer set search_path = '' as $$
  select auth.uid() is not null
    and p_storage_path ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.(jpg|jpeg|png|webp)$'
    and split_part(p_storage_path, '/', 1) = auth.uid()::text
    and split_part(p_storage_path, '/', 2) = p_post_id::text
    and exists (
      select 1 from public.posts p
      where p.id = p_post_id and p.author_id = auth.uid()
        and p.status in ('open', 'coordinating')
    );
$$;

create or replace function public.can_view_post_image_object(p_storage_path text)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.post_images i
    where i.storage_path = p_storage_path
      and public.can_view_post_image(i.post_id)
  );
$$;

alter table public.post_images enable row level security;
revoke all on public.post_images from anon, authenticated;
grant select, insert on public.post_images to authenticated;

drop policy if exists post_images_read_nearby on public.post_images;
create policy post_images_read_nearby on public.post_images
  for select to authenticated using (public.can_view_post_image(post_id));

drop policy if exists post_images_insert_author on public.post_images;
create policy post_images_insert_author on public.post_images
  for insert to authenticated with check (
    author_id = auth.uid()
    and public.can_upload_post_image(storage_path, post_id)
  );

insert into storage.buckets(id, name, public, file_size_limit, allowed_mime_types)
values (
  'yunta-post-images', 'yunta-post-images', false, 5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists yunta_post_images_read on storage.objects;
create policy yunta_post_images_read on storage.objects
  for select to authenticated using (
    bucket_id = 'yunta-post-images'
    and public.can_view_post_image_object(name)
  );

drop policy if exists yunta_post_images_insert on storage.objects;
create policy yunta_post_images_insert on storage.objects
  for insert to authenticated with check (
    bucket_id = 'yunta-post-images'
    and public.can_upload_post_image(
      name,
      case when name ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.(jpg|jpeg|png|webp)$'
        then split_part(name, '/', 2)::uuid else null end
    )
  );

drop policy if exists yunta_post_images_delete_author on storage.objects;
create policy yunta_post_images_delete_author on storage.objects
  for delete to authenticated using (
    bucket_id = 'yunta-post-images'
    and public.can_upload_post_image(
      name,
      case when name ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.(jpg|jpeg|png|webp)$'
        then split_part(name, '/', 2)::uuid else null end
    )
  );

create or replace function public.my_case_threads()
returns table (
  post_id uuid,
  title text,
  category text,
  type text,
  status text,
  coordination_mode text,
  last_message text,
  last_message_at timestamptz,
  member_count integer
)
language sql stable security definer set search_path = '' as $$
  select p.id, p.title, p.category, p.type, p.status, p.coordination_mode,
    latest.body, latest.created_at,
    (select count(*)::integer from public.post_members m
      where m.post_id = p.id and m.user_id <> p.author_id
        and m.status in ('accepted', 'active'))
  from public.posts p
  left join lateral (
    select msg.body, msg.created_at from public.messages msg
    where msg.post_id = p.id order by msg.created_at desc limit 1
  ) latest on true
  where auth.uid() is not null and p.status <> 'cancelled'
    and public.can_access_post(p.id)
    and exists (
      select 1 from public.post_members m
      where m.post_id = p.id and m.user_id <> p.author_id
        and m.status in ('accepted', 'active')
        and (m.user_id = auth.uid() or p.author_id = auth.uid())
    )
  order by coalesce(latest.created_at, p.updated_at) desc;
$$;

revoke all on function public.can_view_post_image(uuid) from public;
revoke all on function public.can_upload_post_image(text, uuid) from public;
revoke all on function public.can_view_post_image_object(text) from public;
revoke all on function public.my_case_threads() from public;
grant execute on function public.can_view_post_image(uuid) to authenticated;
grant execute on function public.can_upload_post_image(text, uuid) to authenticated;
grant execute on function public.can_view_post_image_object(text) to authenticated;
grant execute on function public.my_case_threads() to authenticated;
