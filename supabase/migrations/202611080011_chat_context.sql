alter table public.posts
  add column if not exists chat_id uuid not null default gen_random_uuid();
alter table public.post_members
  add column if not exists chat_id uuid;
alter table public.messages
  add column if not exists chat_id uuid;

update public.post_members pm
set chat_id = p.chat_id
from public.posts p
where pm.post_id = p.id
  and pm.status in ('accepted', 'active')
  and pm.chat_id is null;

update public.messages msg
set chat_id = case
  when p.coordination_mode = 'group' then p.chat_id
  when current_member.chat_id is not null
    and msg.created_at >= current_member.updated_at then p.chat_id
  else gen_random_uuid()
end
from public.posts p
left join public.post_members current_member
  on current_member.post_id = p.id
  and current_member.user_id <> p.author_id
  and current_member.status = 'accepted'
where msg.post_id = p.id
  and msg.chat_id is null;

alter table public.messages
  alter column chat_id set not null;
create index if not exists messages_chat_created_idx
  on public.messages(chat_id, created_at);

create or replace function public.assign_post_member_chat_id()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_chat_id uuid;
begin
  if new.status in ('accepted', 'active') then
    select p.chat_id into v_chat_id
    from public.posts p
    where p.id = new.post_id;
    if v_chat_id is null then
      raise exception 'No se encontró la conversación del caso.';
    end if;
    new.chat_id := v_chat_id;
  end if;
  return new;
end;
$$;

revoke all on function public.assign_post_member_chat_id() from public, anon, authenticated;
drop trigger if exists assign_post_member_chat on public.post_members;
create trigger assign_post_member_chat
before insert or update of status on public.post_members
for each row execute function public.assign_post_member_chat_id();

create or replace function public.reopen_post(p_post_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_post public.posts%rowtype;
  v_chat_id uuid;
begin
  select * into v_post
  from public.posts
  where id = p_post_id
  for update;
  if v_post.author_id is distinct from auth.uid() then
    raise exception 'Solo quien publicó puede reabrir el caso.';
  end if;
  if v_post.coordination_mode <> 'individual'
    or v_post.status not in ('coordinating', 'resolved') then
    raise exception 'Este aviso no se puede reabrir.';
  end if;

  update public.post_members
  set status = 'released', updated_at = now()
  where post_id = p_post_id
    and status in ('accepted', 'pending');

  update public.posts
  set status = 'open', chat_id = gen_random_uuid(),
      closed_at = null, updated_at = now()
  where id = p_post_id
  returning chat_id into v_chat_id;

  update public.post_members
  set chat_id = v_chat_id
  where post_id = p_post_id
    and user_id = v_post.author_id
    and role = 'author'
    and status = 'active';
end;
$$;

create or replace function public.can_access_chat(
  p_post_id uuid,
  p_chat_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.posts p
    where p.id = p_post_id
      and p.chat_id = p_chat_id
      and p.status in ('coordinating', 'resolved')
      and (
        p.author_id = auth.uid()
        or exists (
          select 1
          from public.post_members pm
          where pm.post_id = p.id
            and pm.user_id = auth.uid()
            and pm.status in ('accepted', 'active')
            and pm.chat_id = p_chat_id
        )
      )
  );
$$;

create or replace function public.can_send_message(
  p_post_id uuid,
  p_chat_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.posts p
    where p.id = p_post_id
      and p.chat_id = p_chat_id
      and p.status = 'coordinating'
      and exists (
        select 1
        from public.post_members pm
        where pm.post_id = p.id
          and pm.user_id = auth.uid()
          and pm.status in ('accepted', 'active')
          and pm.chat_id = p.chat_id
      )
  );
$$;

drop policy if exists messages_read_access on public.messages;
drop policy if exists messages_insert_access on public.messages;
revoke all on function public.can_send_message(uuid) from public, anon, authenticated;
drop function if exists public.can_send_message(uuid);
create policy messages_read_access on public.messages
for select to authenticated
using (public.can_access_chat(post_id, chat_id));
create policy messages_insert_access on public.messages
for insert to authenticated
with check (
  sender_id = auth.uid()
  and public.can_send_message(post_id, chat_id)
);

create or replace function public.get_chat_context(p_post_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_context jsonb;
begin
  if auth.uid() is null then
    raise exception 'Debes iniciar sesión.';
  end if;

  select jsonb_build_object(
    'post_id', p.id,
    'chat_id', p.chat_id,
    'title', p.title,
    'category', p.category,
    'type', p.type,
    'status', p.status,
    'coordination_mode', p.coordination_mode,
    'is_author', p.author_id = auth.uid(),
    'author_name', author.display_name,
    'peer_name', case
      when p.coordination_mode <> 'individual' then null
      when p.author_id = auth.uid() then (
        select helper.display_name
        from public.post_members pm
        join public.profiles helper on helper.user_id = pm.user_id
        where pm.post_id = p.id
          and pm.user_id <> p.author_id
          and pm.status = 'accepted'
          and pm.chat_id = p.chat_id
        limit 1
      )
      else author.display_name
    end,
    'distance_m', round(extensions.st_distance(
      p.location,
      extensions.st_setsrid(
        extensions.st_makepoint(me.longitude, me.latitude), 4326
      )::extensions.geography
    ) / 10.0)::integer * 10,
    'member_count', (
      select count(*)::integer
      from public.post_members pm
      where pm.post_id = p.id
        and pm.user_id <> p.author_id
        and pm.status in ('accepted', 'active')
        and pm.chat_id = p.chat_id
    ),
    'participants', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'user_id', pm.user_id,
        'display_name', participant.display_name
      )), '[]'::jsonb)
      from public.post_members pm
      join public.profiles participant on participant.user_id = pm.user_id
      where pm.post_id = p.id
        and pm.status in ('accepted', 'active')
        and pm.chat_id = p.chat_id
    )
  ) into v_context
  from public.posts p
  join public.profiles author on author.user_id = p.author_id
  join public.private_profiles me on me.user_id = auth.uid()
  where p.id = p_post_id
    and public.can_access_chat(p.id, p.chat_id);

  if v_context is null then
    raise exception 'No tienes acceso a esta conversación.';
  end if;
  return v_context;
end;
$$;

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
language sql
stable
security definer
set search_path = ''
as $$
  select p.id, p.title, p.category, p.type, p.status, p.coordination_mode,
    latest.body, latest.created_at,
    (
      select count(*)::integer
      from public.post_members pm
      where pm.post_id = p.id
        and pm.user_id <> p.author_id
        and pm.status in ('accepted', 'active')
        and pm.chat_id = p.chat_id
    )
  from public.posts p
  left join lateral (
    select msg.body, msg.created_at
    from public.messages msg
    where msg.post_id = p.id
      and msg.chat_id = p.chat_id
    order by msg.created_at desc
    limit 1
  ) latest on true
  where auth.uid() is not null
    and p.status in ('coordinating', 'resolved')
    and public.can_access_post(p.id)
    and exists (
      select 1
      from public.post_members pm
      where pm.post_id = p.id
        and pm.user_id <> p.author_id
        and pm.status in ('accepted', 'active')
        and pm.chat_id = p.chat_id
        and (pm.user_id = auth.uid() or p.author_id = auth.uid())
    )
  order by coalesce(latest.created_at, p.updated_at) desc;
$$;

revoke all on function public.can_access_chat(uuid, uuid) from public, anon;
grant execute on function public.can_access_chat(uuid, uuid) to authenticated;
revoke all on function public.can_send_message(uuid, uuid) from public, anon;
grant execute on function public.can_send_message(uuid, uuid) to authenticated;
revoke all on function public.get_chat_context(uuid) from public, anon;
grant execute on function public.get_chat_context(uuid) to authenticated;
revoke all on function public.my_case_threads() from public, anon;
grant execute on function public.my_case_threads() to authenticated;
revoke all on function public.reopen_post(uuid) from public, anon;
grant execute on function public.reopen_post(uuid) to authenticated;

