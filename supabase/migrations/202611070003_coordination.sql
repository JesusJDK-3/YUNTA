create or replace function public.accept_post_offer(p_post_id uuid, p_user_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare v_post public.posts%rowtype; v_role text;
begin
  select * into v_post from public.posts where id = p_post_id for update;
  if v_post.author_id is distinct from auth.uid() then raise exception 'Solo quien publicó puede elegir.'; end if;
  if v_post.status not in ('open', 'coordinating') or v_post.coordination_mode <> 'individual' then raise exception 'Este aviso no admite asignación individual.'; end if;
  if not exists (select 1 from public.post_members where post_id = p_post_id and user_id = p_user_id and status = 'pending') then
    raise exception 'La oferta ya no está pendiente.';
  end if;
  v_role := case when v_post.type in ('help_request', 'urgent_request') then 'provider' else 'recipient' end;
  update public.post_members set status = 'released', updated_at = now()
  where post_id = p_post_id and status = 'accepted';
  update public.post_members set status = 'accepted', role = v_role, updated_at = now()
  where post_id = p_post_id and user_id = p_user_id;
  update public.posts set status = 'coordinating', updated_at = now() where id = p_post_id;
end;
$$;

create or replace function public.reopen_post(p_post_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare v_post public.posts%rowtype;
begin
  select * into v_post from public.posts where id = p_post_id for update;
  if v_post.author_id is distinct from auth.uid() then raise exception 'Solo quien publicó puede reabrir el caso.'; end if;
  if v_post.coordination_mode <> 'individual' or v_post.status not in ('coordinating', 'resolved') then
    raise exception 'Este aviso no se puede reabrir.';
  end if;
  update public.post_members set status = 'released', updated_at = now()
  where post_id = p_post_id and status in ('accepted', 'pending');
  update public.posts set status = 'open', closed_at = null, updated_at = now() where id = p_post_id;
end;
$$;

create or replace function public.resolve_post(p_post_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
  update public.posts set status = 'resolved', closed_at = now(), updated_at = now()
  where id = p_post_id and author_id = auth.uid() and status in ('open', 'coordinating');
  if not found then raise exception 'No se pudo cerrar el aviso.'; end if;
end;
$$;

create or replace function public.cancel_post(p_post_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
  update public.posts set status = 'cancelled', closed_at = now(), updated_at = now()
  where id = p_post_id and author_id = auth.uid() and status in ('open', 'coordinating');
  if not found then raise exception 'No se pudo retirar el aviso.'; end if;
  update public.post_members set status = 'released', updated_at = now()
  where post_id = p_post_id and user_id <> auth.uid();
end;
$$;

create or replace function public.edit_local_ad(
  p_post_id uuid, p_title text, p_description text, p_area_label text
)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if p_title is null or char_length(trim(p_title)) not between 4 and 100 then raise exception 'Revisa el título.'; end if;
  if p_description is null or char_length(trim(p_description)) not between 8 and 1200 then raise exception 'Revisa la descripción.'; end if;
  if p_area_label is null or char_length(trim(p_area_label)) not between 2 and 80 or p_area_label ~* '([0-9#]|(^|[^[:alpha:]])(calle|avenida|av|jr|jiron|jirón|mz|manzana|lote|lt|dpto|depto|departamento|interior|int|piso|nro|numero|pasaje|psje|carretera)([^[:alpha:]]|$))' then
    raise exception 'Usa solo el nombre aproximado del barrio, sin calle ni número.';
  end if;
  if concat_ws(' ', p_title, p_description) ~* '(\+?[0-9][0-9[:space:]().-]{7,}[0-9]|(^|[^[:alpha:]])(calle|cal|avenida|av|jr|jiron|jirón|mz|manzana|lote|lt|dpto|depto|departamento|interior|int|piso|nro|numero|pasaje|psje|carretera)([^[:alpha:]]|$)[^.!?\n]{0,120}[0-9]{1,5}|(^|[^0-9])[0-9]{1,5}[[:space:]]*,[[:space:]]*(calle|cal|avenida|av|jr|jiron|jirón|pasaje|psje|carretera)([^[:alpha:]]|$))' then
    raise exception 'No publiques celulares ni direcciones exactas; compártelos en el chat.';
  end if;
  update public.posts set title = trim(p_title), description = trim(p_description),
    area_label = trim(p_area_label), updated_at = now()
  where id = p_post_id and author_id = auth.uid() and category = 'products_services'
    and status in ('open', 'coordinating');
  if not found then raise exception 'No se pudo editar el anuncio.'; end if;
end;
$$;

create or replace function public.recommend_ad(p_post_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
  insert into public.recommendations(post_id, user_id)
  select p.id, auth.uid() from public.posts p
  where p.id = p_post_id and p.category = 'products_services' and p.status in ('open', 'coordinating') and p.author_id <> auth.uid()
    and exists (select 1 from public.private_profiles me where me.user_id = auth.uid()
      and extensions.st_dwithin(p.location, extensions.st_setsrid(extensions.st_makepoint(me.longitude, me.latitude), 4326)::extensions.geography, 500))
  on conflict (post_id, user_id) do nothing;
  if not found then raise exception 'No se pudo recomendar este anuncio.'; end if;
end;
$$;

create or replace function public.rate_provider(
  p_post_id uuid, p_score smallint, p_comment text default null
)
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_post public.posts%rowtype; v_provider uuid; v_reviewer uuid := auth.uid(); v_rating uuid;
begin
  select * into v_post from public.posts where id = p_post_id;
  if v_post.id is null or v_post.status <> 'resolved' or v_post.coordination_mode <> 'individual' then
    raise exception 'La valoración está disponible al resolver un caso individual.';
  end if;
  if p_score not between 1 and 5 or char_length(coalesce(p_comment, '')) > 500 then raise exception 'Revisa la valoración.'; end if;
  if v_post.type in ('help_request', 'urgent_request') then
    v_reviewer := v_post.author_id;
    select user_id into v_provider from public.post_members
    where post_id = p_post_id and role = 'provider' and status = 'accepted';
  else
    select user_id into v_reviewer from public.post_members
    where post_id = p_post_id and role = 'recipient' and status = 'accepted';
    v_provider := v_post.author_id;
  end if;
  if v_reviewer is distinct from auth.uid() or v_provider is null or v_provider = v_reviewer then
    raise exception 'Solo quien recibió la ayuda puede valorar a quien la prestó.';
  end if;
  insert into public.ratings(post_id, reviewer_id, reviewed_user_id, score, comment)
  values (p_post_id, v_reviewer, v_provider, p_score, nullif(trim(p_comment), ''))
  returning id into v_rating;
  return v_rating;
end;
$$;

revoke all on function public.accept_post_offer(uuid, uuid) from public;
revoke all on function public.reopen_post(uuid) from public;
revoke all on function public.resolve_post(uuid) from public;
revoke all on function public.cancel_post(uuid) from public;
revoke all on function public.edit_local_ad(uuid, text, text, text) from public;
revoke all on function public.recommend_ad(uuid) from public;
revoke all on function public.rate_provider(uuid, smallint, text) from public;
grant execute on function public.accept_post_offer(uuid, uuid) to authenticated;
grant execute on function public.reopen_post(uuid) to authenticated;
grant execute on function public.resolve_post(uuid) to authenticated;
grant execute on function public.cancel_post(uuid) to authenticated;
grant execute on function public.edit_local_ad(uuid, text, text, text) to authenticated;
grant execute on function public.recommend_ad(uuid) to authenticated;
grant execute on function public.rate_provider(uuid, smallint, text) to authenticated;

