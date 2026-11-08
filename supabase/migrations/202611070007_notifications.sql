create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references auth.users(id) on delete cascade,
  actor_id uuid not null references auth.users(id) on delete cascade,
  post_id uuid not null references public.posts(id) on delete cascade,
  kind text not null check (kind in ('offer_received', 'group_joined', 'offer_accepted')),
  actor_name text not null,
  post_title text not null,
  created_at timestamptz not null default now(),
  read_at timestamptz,
  check (recipient_id <> actor_id)
);

create index if not exists notifications_recipient_created_idx
  on public.notifications(recipient_id, created_at desc);

alter table public.notifications enable row level security;
revoke all on public.notifications from anon, authenticated;
grant select on public.notifications to authenticated;
grant update(read_at) on public.notifications to authenticated;

drop policy if exists notifications_read_own on public.notifications;
create policy notifications_read_own on public.notifications
  for select to authenticated using (recipient_id = auth.uid());
drop policy if exists notifications_mark_own on public.notifications;
create policy notifications_mark_own on public.notifications
  for update to authenticated
  using (recipient_id = auth.uid())
  with check (recipient_id = auth.uid());

create or replace function public.notify_post_member_activity()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  v_author uuid;
  v_post_title text;
  v_recipient uuid;
  v_actor uuid;
  v_actor_name text;
  v_kind text;
begin
  if tg_op = 'UPDATE' and new.status is not distinct from old.status then
    return new;
  end if;

  select p.author_id, p.title into v_author, v_post_title
  from public.posts p where p.id = new.post_id;
  if v_author is null or new.user_id = v_author then return new; end if;

  if new.status = 'pending' then
    v_recipient := v_author;
    v_actor := new.user_id;
    v_kind := 'offer_received';
  elsif new.status = 'active' then
    v_recipient := v_author;
    v_actor := new.user_id;
    v_kind := 'group_joined';
  elsif new.status = 'accepted' then
    v_recipient := new.user_id;
    v_actor := v_author;
    v_kind := 'offer_accepted';
  else
    return new;
  end if;

  select p.display_name into v_actor_name
  from public.profiles p where p.user_id = v_actor;

  insert into public.notifications(
    recipient_id, actor_id, post_id, kind, actor_name, post_title
  ) values (
    v_recipient, v_actor, new.post_id, v_kind,
    coalesce(v_actor_name, 'Vecino'), v_post_title
  );
  return new;
end;
$$;
revoke all on function public.notify_post_member_activity() from public, anon, authenticated;

drop trigger if exists post_member_activity_notification on public.post_members;
create trigger post_member_activity_notification
  after insert or update of status on public.post_members
  for each row execute function public.notify_post_member_activity();

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'notifications'
  ) then
    alter publication supabase_realtime add table public.notifications;
  end if;
end $$;
