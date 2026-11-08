create or replace function public.join_post(p_post_id uuid)
returns text language plpgsql security definer set search_path = '' as $$
declare v_post public.posts%rowtype;
begin
  select * into v_post from public.posts where id = p_post_id for update;
  if v_post.id is null or v_post.status not in ('open', 'coordinating') then
    raise exception 'El caso ya no acepta participantes.';
  end if;
  if v_post.author_id = auth.uid() then raise exception 'Este aviso es tuyo.'; end if;
  if not exists (
    select 1 from public.private_profiles me
    where me.user_id = auth.uid() and extensions.st_dwithin(v_post.location,
      extensions.st_setsrid(extensions.st_makepoint(me.longitude, me.latitude), 4326)::extensions.geography, 500)
  ) then raise exception 'Este aviso está fuera de tu zona cercana.'; end if;
  if v_post.coordination_mode = 'group' then
    insert into public.post_members(post_id, user_id, role, status)
    values (p_post_id, auth.uid(), 'participant', 'active')
    on conflict (post_id, user_id) do update
      set status = 'active', role = 'participant', updated_at = now();
    update public.posts set status = 'coordinating', updated_at = now()
    where id = p_post_id;
    return 'active';
  end if;
  if v_post.status <> 'open' then
    raise exception 'Este caso ya está coordinando con un vecino.';
  end if;
  insert into public.post_members(post_id, user_id, role, status)
  values (p_post_id, auth.uid(), 'participant', 'pending')
  on conflict (post_id, user_id) do update
    set status = 'pending', role = 'participant', updated_at = now();
  return 'pending';
end;
$$;

create or replace function public.accept_post_offer(p_post_id uuid, p_user_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare v_post public.posts%rowtype; v_role text;
begin
  select * into v_post from public.posts where id = p_post_id for update;
  if v_post.author_id is distinct from auth.uid() then
    raise exception 'Solo quien publicó puede elegir.';
  end if;
  if v_post.status <> 'open' or v_post.coordination_mode <> 'individual' then
    raise exception 'Reabre el caso antes de elegir a otra persona.';
  end if;
  if not exists (
    select 1 from public.post_members
    where post_id = p_post_id and user_id = p_user_id and status = 'pending'
  ) then raise exception 'La oferta ya no está pendiente.'; end if;
  v_role := case when v_post.type in ('help_request', 'urgent_request')
    then 'provider' else 'recipient' end;
  update public.post_members set status = 'released', updated_at = now()
  where post_id = p_post_id and user_id <> p_user_id
    and status in ('accepted', 'pending');
  update public.post_members set status = 'accepted', role = v_role,
    updated_at = now()
  where post_id = p_post_id and user_id = p_user_id;
  update public.posts set status = 'coordinating', updated_at = now()
  where id = p_post_id;
end;
$$;
