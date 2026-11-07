create or replace function public.save_my_profile(
  p_display_name text,
  p_phone_e164 text,
  p_area_label text,
  p_latitude double precision,
  p_longitude double precision,
  p_location_source text,
  p_tutorial_completed boolean default false
)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null or auth.role() <> 'authenticated' then raise exception 'Debes iniciar sesión.'; end if;
  if char_length(trim(p_display_name)) not between 2 and 60 then raise exception 'Revisa tu nombre.'; end if;
  if p_phone_e164 !~ '^\+[1-9][0-9]{7,14}$' then raise exception 'Revisa el número de celular.'; end if;
  if char_length(trim(p_area_label)) not between 2 and 80 or p_area_label ~* '([0-9#]|(^|[^[:alpha:]])(calle|avenida|av|jr|jiron|jirón|mz|manzana|lote|lt|dpto|depto|departamento|interior|int|piso|nro|numero|pasaje|psje|carretera)([^[:alpha:]]|$))' then raise exception 'Usa solo el nombre aproximado del barrio, sin calle ni número.'; end if;
  if p_latitude not between -90 and 90 or p_longitude not between -180 and 180 then raise exception 'Ubicación inválida.'; end if;
  if p_location_source not in ('gps', 'manual') then raise exception 'Origen de ubicación inválido.'; end if;
  insert into public.profiles(user_id, display_name)
  values (auth.uid(), trim(p_display_name))
  on conflict (user_id) do update set display_name = excluded.display_name, updated_at = now();
  insert into public.private_profiles(user_id, phone_e164, area_label, latitude, longitude, location_source)
  values (auth.uid(), p_phone_e164, trim(p_area_label), p_latitude, p_longitude, p_location_source)
  on conflict (user_id) do update set phone_e164 = excluded.phone_e164, area_label = excluded.area_label, latitude = excluded.latitude,
    longitude = excluded.longitude, location_source = excluded.location_source, updated_at = now();
  insert into public.user_settings(user_id, tutorial_completed_at)
  values (auth.uid(), case when p_tutorial_completed then now() end)
  on conflict (user_id) do update set tutorial_completed_at =
    case when p_tutorial_completed then coalesce(public.user_settings.tutorial_completed_at, now())
    else public.user_settings.tutorial_completed_at end, updated_at = now();
end;
$$;

create or replace function public.get_my_profile()
returns jsonb language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'display_name', p.display_name, 'phone_e164', v.phone_e164, 'area_label', v.area_label,
    'latitude', v.latitude, 'longitude', v.longitude,
    'location_source', v.location_source, 'tutorial_completed_at', s.tutorial_completed_at
  )
  from public.profiles p
  join public.private_profiles v on v.user_id = p.user_id
  join public.user_settings s on s.user_id = p.user_id
  where p.user_id = auth.uid();
$$;

create or replace function public.nearby_posts(p_category text default null)
returns table (
  id uuid, category text, type text, title text, description text,
  coordination_mode text, status text, area_label text, created_at timestamptz,
  author_id uuid, author_name text, distance_m integer,
  recommendation_count bigint, member_count integer, my_membership text
)
language sql stable security definer set search_path = '' as $$
  select p.id, p.category, p.type, p.title, p.description, p.coordination_mode,
    p.status, p.area_label, p.created_at, p.author_id, pr.display_name,
    round(extensions.st_distance(p.location, extensions.st_setsrid(
      extensions.st_makepoint(me.longitude, me.latitude), 4326
    )::extensions.geography) / 10.0)::integer * 10,
    (select count(*) from public.recommendations r where r.post_id = p.id),
    (select count(*)::integer from public.post_members m where m.post_id = p.id and m.user_id <> p.author_id and m.status in ('active', 'accepted')),
    (select m.status from public.post_members m where m.post_id = p.id and m.user_id = auth.uid())
  from public.posts p
  join public.profiles pr on pr.user_id = p.author_id
  join public.private_profiles me on me.user_id = auth.uid()
  where auth.uid() is not null and p.status in ('open', 'coordinating')
    and (p_category is null or p.category = p_category)
    and extensions.st_dwithin(p.location, extensions.st_setsrid(
      extensions.st_makepoint(me.longitude, me.latitude), 4326
    )::extensions.geography, 500)
  order by p.created_at desc;
$$;

create or replace function public.get_post_detail(p_post_id uuid)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare result jsonb;
begin
  select jsonb_build_object(
    'id', p.id, 'category', p.category, 'type', p.type, 'title', p.title,
    'description', p.description, 'coordination_mode', p.coordination_mode,
    'status', p.status, 'area_label', p.area_label, 'created_at', p.created_at,
    'author_id', p.author_id, 'author_name', pr.display_name,
    'provider_name', case
      when p.status = 'resolved' and p.coordination_mode = 'individual' and (
        (auth.uid() = p.author_id and p.type in ('help_request', 'urgent_request'))
        or (auth.uid() <> p.author_id and p.type not in ('help_request', 'urgent_request')
          and exists (select 1 from public.post_members rm where rm.post_id = p.id
            and rm.user_id = auth.uid() and rm.role = 'recipient' and rm.status = 'accepted'))
      ) then case when p.type in ('help_request', 'urgent_request') then (
        select provider.display_name from public.post_members pm
        join public.profiles provider on provider.user_id = pm.user_id
        where pm.post_id = p.id and pm.role = 'provider' and pm.status = 'accepted'
      ) else pr.display_name end
      else null end,
    'distance_m', round(extensions.st_distance(p.location, extensions.st_setsrid(
      extensions.st_makepoint(me.longitude, me.latitude), 4326
    )::extensions.geography) / 10.0)::integer * 10,
    'member_count', (select count(*) from public.post_members m where m.post_id = p.id and m.user_id <> p.author_id and m.status in ('active', 'accepted')),
    'recommendation_count', (select count(*) from public.recommendations r where r.post_id = p.id),
    'has_recommended', exists (select 1 from public.recommendations r where r.post_id = p.id and r.user_id = auth.uid()),
    'my_rating', (select r.id from public.ratings r where r.post_id = p.id and r.reviewer_id = auth.uid()),
    'my_membership', (select m.status from public.post_members m where m.post_id = p.id and m.user_id = auth.uid()),
    'offers', case when p.author_id = auth.uid() then (
      select coalesce(jsonb_agg(jsonb_build_object('user_id', m.user_id, 'display_name', pr2.display_name, 'joined_at', m.joined_at)), '[]'::jsonb)
      from public.post_members m join public.profiles pr2 on pr2.user_id = m.user_id
      where m.post_id = p.id and m.status = 'pending'
    ) else '[]'::jsonb end
  ) into result
  from public.posts p
  join public.profiles pr on pr.user_id = p.author_id
  join public.private_profiles me on me.user_id = auth.uid()
  where p.id = p_post_id and (
    p.author_id = auth.uid() or (p.status in ('open', 'coordinating') and extensions.st_dwithin(p.location, extensions.st_setsrid(
      extensions.st_makepoint(me.longitude, me.latitude), 4326
    )::extensions.geography, 500)) or public.can_access_post(p.id)
  );
  if result is null then raise exception 'El aviso no está disponible cerca de ti.'; end if;
  return result;
end;
$$;

create or replace function public.create_post(
  p_id uuid, p_category text, p_type text, p_title text, p_description text,
  p_mode text, p_latitude double precision, p_longitude double precision, p_area_label text
)
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_author uuid := auth.uid(); v_id uuid;
begin
  if v_author is null or auth.role() <> 'authenticated' then raise exception 'Debes iniciar sesión.'; end if;
  if p_title is null or char_length(trim(p_title)) not between 4 and 100 then raise exception 'El título debe tener entre 4 y 100 caracteres.'; end if;
  if p_description is null or char_length(trim(p_description)) not between 8 and 1200 then raise exception 'La descripción debe tener entre 8 y 1200 caracteres.'; end if;
  if p_area_label is null or char_length(trim(p_area_label)) not between 2 and 80 or p_area_label ~* '([0-9#]|(^|[^[:alpha:]])(calle|avenida|av|jr|jiron|jirón|mz|manzana|lote|lt|dpto|depto|departamento|interior|int|piso|nro|numero|pasaje|psje|carretera)([^[:alpha:]]|$))' then
    raise exception 'Usa solo el nombre aproximado del barrio, sin calle ni número.';
  end if;
  if concat_ws(' ', p_title, p_description) ~* '(\+?[0-9][0-9[:space:]().-]{7,}[0-9]|(^|[^[:alpha:]])(calle|cal|avenida|av|jr|jiron|jirón|mz|manzana|lote|lt|dpto|depto|departamento|interior|int|piso|nro|numero|pasaje|psje|carretera)([^[:alpha:]]|$)[^.!?\n]{0,120}[0-9]{1,5}|(^|[^0-9])[0-9]{1,5}[[:space:]]*,[[:space:]]*(calle|cal|avenida|av|jr|jiron|jirón|pasaje|psje|carretera)([^[:alpha:]]|$))' then
    raise exception 'No publiques celulares ni direcciones exactas; compártelos en el chat.';
  end if;
  if p_latitude not between -90 and 90 or p_longitude not between -180 and 180 then raise exception 'Ubicación inválida.'; end if;
  if not exists (select 1 from public.private_profiles where user_id = v_author) then raise exception 'Completa tu perfil antes de publicar.'; end if;
  insert into public.posts(id, author_id, category, type, title, description, coordination_mode, latitude, longitude, area_label)
  values (p_id, v_author, p_category, p_type, trim(p_title), trim(p_description), p_mode, p_latitude, p_longitude, trim(p_area_label))
  on conflict (id) do nothing returning id into v_id;
  if v_id is null then
    if not exists (select 1 from public.posts p where p.id = p_id and p.author_id = v_author) then raise exception 'Identificador de aviso ocupado.'; end if;
    return p_id;
  end if;
  insert into public.post_members(post_id, user_id, role, status) values (v_id, v_author, 'author', 'active');
  return v_id;
end;
$$;

create or replace function public.join_post(p_post_id uuid)
returns text language plpgsql security definer set search_path = '' as $$
declare v_post public.posts%rowtype;
begin
  select * into v_post from public.posts where id = p_post_id for update;
  if v_post.id is null or v_post.status not in ('open', 'coordinating') then raise exception 'El caso ya no acepta participantes.'; end if;
  if v_post.author_id = auth.uid() then raise exception 'Este aviso es tuyo.'; end if;
  if not exists (
    select 1 from public.private_profiles me
    where me.user_id = auth.uid() and extensions.st_dwithin(v_post.location,
      extensions.st_setsrid(extensions.st_makepoint(me.longitude, me.latitude), 4326)::extensions.geography, 500)
  ) then raise exception 'Este aviso está fuera de tu zona cercana.'; end if;
  if v_post.coordination_mode = 'group' then
    insert into public.post_members(post_id, user_id, role, status)
    values (p_post_id, auth.uid(), 'participant', 'active')
    on conflict (post_id, user_id) do update set status = 'active', role = 'participant', updated_at = now();
    update public.posts set status = 'coordinating', updated_at = now() where id = p_post_id;
    return 'active';
  end if;
  insert into public.post_members(post_id, user_id, role, status)
  values (p_post_id, auth.uid(), 'participant', 'pending')
  on conflict (post_id, user_id) do update set status = 'pending', role = 'participant', updated_at = now();
  return 'pending';
end;
$$;

revoke all on function public.save_my_profile(text, text, text, double precision, double precision, text, boolean) from public;
revoke all on function public.get_my_profile() from public;
revoke all on function public.nearby_posts(text) from public;
revoke all on function public.get_post_detail(uuid) from public;
revoke all on function public.create_post(uuid, text, text, text, text, text, double precision, double precision, text) from public;
revoke all on function public.join_post(uuid) from public;
grant execute on function public.save_my_profile(text, text, text, double precision, double precision, text, boolean) to authenticated;
grant execute on function public.get_my_profile() to authenticated;
grant execute on function public.nearby_posts(text) to authenticated;
grant execute on function public.get_post_detail(uuid) to authenticated;
grant execute on function public.create_post(uuid, text, text, text, text, text, double precision, double precision, text) to authenticated;
grant execute on function public.join_post(uuid) to authenticated;

