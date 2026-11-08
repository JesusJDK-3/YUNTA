-- El muro no acepta un celular ni una calle con número.
-- Misma idea que assertPublicText en src/domain/rules.ts.
create or replace function public.assert_public_text(p_title text, p_description text, p_area text)
returns void
language plpgsql
as $$
declare
  v_text text := concat_ws(E'\n', coalesce(p_title, ''), coalesce(p_description, ''));
begin
  if v_text ~ '(\+?[0-9][0-9[:space:]().-]{7,}[0-9])' then
    perform public.raise_yunta('private_text');
  end if;
  if concat_ws(E'\n', v_text, coalesce(p_area, '')) ~* '(calle|avenida|jir[oó]n|manzana|pasaje|departamento)[^[:cntrl:]]{0,40}[0-9]{1,5}' then
    perform public.raise_yunta('private_text');
  end if;
end;
$$;

-- Acciones de Yunta. Cada una vuelve a comprobar el papel de la persona:
-- la interfaz puede esconder un botón, pero la base no confía en eso.
-- Mantener alineado con specFromIntent en src/domain/rules.ts.

create or replace function public.publicar(
  p_intent text,
  p_help_type text,
  p_title text,
  p_description text,
  p_area_label text,
  p_lat double precision,
  p_lng double precision,
  p_client_request_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := public.yunta_uid();
  v_zone text := public.yunta_zone();
  v_existing uuid;
  v_id uuid := gen_random_uuid();
  v_kind text;
  v_category text;
  v_type text;
  v_mode text;
  v_role text;
  v_status text;
  v_title text := btrim(coalesce(p_title, ''));
  v_description text := btrim(coalesce(p_description, ''));
  v_area text := btrim(coalesce(p_area_label, ''));
  v_geom geography;
begin
  if char_length(v_title) < 3 or char_length(v_title) > 80 or char_length(v_description) > 500 then
    perform public.raise_yunta('validation');
  end if;
  perform public.assert_public_text(v_title, v_description, v_area);
  if (p_lat is null) <> (p_lng is null)
     or (p_lat is not null and (p_lat < -90 or p_lat > 90 or p_lng < -180 or p_lng > 180)) then
    perform public.raise_yunta('validation');
  end if;

  select id into v_existing
  from public.publicaciones
  where author_id = v_uid and client_request_id = p_client_request_id;
  if v_existing is not null then
    return jsonb_build_object('id', v_existing, 'deduped', true);
  end if;

  if (select count(*) from public.publicaciones
      where author_id = v_uid and created_at > now() - interval '1 hour') >= 8 then
    perform public.raise_yunta('rate_limit');
  end if;

  -- Misma tabla que specFromIntent.
  if p_intent = 'pido_ayuda' then
    v_kind := 'caso'; v_category := 'ayuda'; v_type := p_help_type;
    v_mode := 'individual'; v_role := 'receptor'; v_status := 'abierto';
  elsif p_intent = 'ofrezco_ayuda' then
    v_kind := 'caso'; v_category := 'ayuda'; v_type := p_help_type;
    v_mode := 'individual'; v_role := 'prestador'; v_status := 'abierto';
  elsif p_intent = 'producto' then
    v_kind := 'anuncio'; v_category := 'producto'; v_type := 'producto';
    v_mode := null; v_role := null; v_status := 'activo';
  elsif p_intent = 'servicio' then
    v_kind := 'anuncio'; v_category := 'servicio'; v_type := 'servicio';
    v_mode := null; v_role := null; v_status := 'activo';
  elsif p_intent = 'emergencia_persona' then
    v_kind := 'caso'; v_category := 'emergencia'; v_type := 'persona';
    v_mode := 'individual'; v_role := 'receptor'; v_status := 'abierto';
  elsif p_intent = 'emergencia_cuadra' then
    v_kind := 'caso'; v_category := 'emergencia'; v_type := 'cuadra';
    v_mode := 'grupal'; v_role := 'participante'; v_status := 'abierto';
  elsif p_intent = 'emergencia_recurso' then
    v_kind := 'caso'; v_category := 'emergencia'; v_type := 'recurso';
    v_mode := 'grupal'; v_role := 'participante'; v_status := 'abierto';
  elsif p_intent = 'grupo_apoyo' then
    v_kind := 'anuncio'; v_category := 'grupo_de_apoyo'; v_type := 'grupo_de_apoyo';
    v_mode := null; v_role := null; v_status := 'activo';
  else
    perform public.raise_yunta('validation');
  end if;

  if p_intent in ('pido_ayuda', 'ofrezco_ayuda')
     and p_help_type not in ('herramienta', 'ayuda_temporal', 'donacion', 'habilidad', 'movilidad') then
    perform public.raise_yunta('validation');
  end if;

  if v_area = '' then
    select name into v_area from public.zones where id = v_zone;
  end if;
  if char_length(v_area) > 40 then
    perform public.raise_yunta('validation');
  end if;

  if p_lat is null then
    select center into v_geom from public.zones where id = v_zone;
  else
    v_geom := ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography;
  end if;

  insert into public.publicaciones (
    id, author_id, kind, category, type, zone_id, title, description,
    coordination_mode, status, area_label, geom, client_request_id
  ) values (
    v_id, v_uid, v_kind, v_category, v_type, v_zone, v_title, v_description,
    v_mode, v_status, v_area, v_geom, p_client_request_id
  );

  if v_role is not null then
    insert into public.miembros (publicacion_id, user_id, role, status)
    values (v_id, v_uid, v_role, 'aceptado');
  end if;

  return jsonb_build_object('id', v_id, 'deduped', false);
end;
$$;

create or replace function public.coordinar(p_anuncio_id uuid, p_client_request_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := public.yunta_uid();
  v_anuncio public.publicaciones;
  v_existing uuid;
  v_id uuid := gen_random_uuid();
begin
  select id into v_existing
  from public.publicaciones
  where author_id = v_uid and client_request_id = p_client_request_id;
  if v_existing is not null then
    return jsonb_build_object('id', v_existing, 'deduped', true);
  end if;

  select * into v_anuncio from public.publicaciones where id = p_anuncio_id;
  if not found or v_anuncio.kind <> 'anuncio' or v_anuncio.status <> 'activo' then
    perform public.raise_yunta('conflict');
  end if;
  if v_anuncio.author_id = v_uid then
    perform public.raise_yunta('self_action');
  end if;
  if v_anuncio.zone_id <> public.yunta_zone() then
    perform public.raise_yunta('zone_mismatch');
  end if;
  if public.par_bloqueado(v_uid, v_anuncio.author_id) then
    perform public.raise_yunta('blocked');
  end if;

  select id into v_existing
  from public.publicaciones
  where source_anuncio_id = v_anuncio.id
    and author_id = v_uid
    and status in ('abierto', 'en_coordinacion')
  limit 1;
  if v_existing is not null then
    return jsonb_build_object('id', v_existing, 'deduped', true);
  end if;

  -- El anuncio no cambia de estado. El caso es otro registro.
  insert into public.publicaciones (
    id, author_id, kind, category, type, zone_id, title, description,
    coordination_mode, status, source_anuncio_id, area_label, geom, client_request_id
  ) values (
    v_id, v_uid, 'caso', v_anuncio.category, 'coordinacion', v_anuncio.zone_id,
    v_anuncio.title, v_anuncio.description, 'individual', 'abierto', v_anuncio.id,
    v_anuncio.area_label, v_anuncio.geom, p_client_request_id
  );
  insert into public.miembros (publicacion_id, user_id, role, status) values
    (v_id, v_uid, 'receptor', 'pendiente'),
    (v_id, v_anuncio.author_id, 'prestador', 'aceptado');

  return jsonb_build_object('id', v_id, 'deduped', false);
end;
$$;

create or replace function public.pedir_entrada(p_caso_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := public.yunta_uid();
  v_pub public.publicaciones;
  v_author_role text;
  v_role text;
  v_status text;
begin
  select * into v_pub from public.publicaciones where id = p_caso_id;
  if not found or v_pub.kind <> 'caso' or v_pub.coordination_mode <> 'individual'
     or v_pub.status not in ('abierto', 'en_coordinacion') then
    perform public.raise_yunta('conflict');
  end if;
  if v_pub.author_id = v_uid then
    perform public.raise_yunta('self_action');
  end if;
  if public.par_bloqueado(v_uid, v_pub.author_id) then
    perform public.raise_yunta('blocked');
  end if;

  select role into v_author_role
  from public.miembros
  where publicacion_id = p_caso_id and user_id = v_pub.author_id;
  v_role := case when v_author_role = 'receptor' then 'prestador' else 'receptor' end;

  if exists (
    select 1 from public.miembros
    where publicacion_id = p_caso_id and role = v_role and status = 'aceptado'
  ) then
    perform public.raise_yunta('slot_taken');
  end if;

  select status into v_status
  from public.miembros
  where publicacion_id = p_caso_id and user_id = v_uid;
  if v_status = 'aceptado' then
    return;
  end if;
  if v_status = 'retirado' then
    perform public.raise_yunta('forbidden');
  end if;

  insert into public.miembros (publicacion_id, user_id, role, status)
  values (p_caso_id, v_uid, v_role, 'pendiente')
  on conflict (publicacion_id, user_id) do update
    set role = excluded.role, status = 'pendiente';
end;
$$;

create or replace function public.aceptar_miembro(p_caso_id uuid, p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := public.yunta_uid();
  v_pub public.publicaciones;
  v_my public.miembros;
  v_target public.miembros;
begin
  select * into v_pub from public.publicaciones where id = p_caso_id;
  if not found or v_pub.coordination_mode <> 'individual'
     or v_pub.status not in ('abierto', 'en_coordinacion') then
    perform public.raise_yunta('conflict');
  end if;
  select * into v_my from public.miembros
  where publicacion_id = p_caso_id and user_id = v_uid and status = 'aceptado';
  if not found then
    perform public.raise_yunta('forbidden');
  end if;
  select * into v_target from public.miembros
  where publicacion_id = p_caso_id and user_id = p_user_id and status = 'pendiente';
  if not found then
    perform public.raise_yunta('forbidden');
  end if;
  if (v_my.role = 'receptor' and v_target.role <> 'prestador')
     or (v_my.role = 'prestador' and v_target.role <> 'receptor') then
    perform public.raise_yunta('forbidden');
  end if;
  if exists (
    select 1 from public.miembros
    where publicacion_id = p_caso_id and role = v_target.role and status = 'aceptado'
  ) then
    perform public.raise_yunta('slot_taken');
  end if;

  update public.miembros
  set status = 'retirado'
  where publicacion_id = p_caso_id
    and role = v_target.role
    and status = 'pendiente'
    and user_id <> p_user_id;
  update public.miembros
  set status = 'aceptado', joined_at = now()
  where publicacion_id = p_caso_id and user_id = p_user_id;
  update public.publicaciones set status = 'en_coordinacion' where id = p_caso_id;
end;
$$;

create or replace function public.rechazar_miembro(p_caso_id uuid, p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := public.yunta_uid();
  v_my_role text;
  v_target_role text;
begin
  select role into v_my_role from public.miembros
  where publicacion_id = p_caso_id and user_id = v_uid and status = 'aceptado';
  select role into v_target_role from public.miembros
  where publicacion_id = p_caso_id and user_id = p_user_id and status = 'pendiente';
  if v_my_role is null or v_target_role is null then
    perform public.raise_yunta('forbidden');
  end if;
  if (v_my_role = 'receptor' and v_target_role <> 'prestador')
     or (v_my_role = 'prestador' and v_target_role <> 'receptor') then
    perform public.raise_yunta('forbidden');
  end if;
  update public.miembros set status = 'retirado'
  where publicacion_id = p_caso_id and user_id = p_user_id;
end;
$$;

create or replace function public.unirme(p_caso_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := public.yunta_uid();
  v_pub public.publicaciones;
  v_status text;
begin
  select * into v_pub from public.publicaciones where id = p_caso_id;
  if not found or v_pub.kind <> 'caso' or v_pub.coordination_mode <> 'grupal' then
    perform public.raise_yunta('conflict');
  end if;
  if v_pub.status in ('resuelto', 'cancelado') then
    perform public.raise_yunta('chat_closed');
  end if;
  if v_pub.author_id = v_uid then
    return;
  end if;
  if public.par_bloqueado(v_uid, v_pub.author_id) then
    perform public.raise_yunta('blocked');
  end if;
  select status into v_status from public.miembros
  where publicacion_id = p_caso_id and user_id = v_uid;
  if v_status = 'retirado' then
    perform public.raise_yunta('forbidden');
  end if;
  if v_status = 'aceptado' then
    return;
  end if;
  insert into public.miembros (publicacion_id, user_id, role, status)
  values (p_caso_id, v_uid, 'participante', 'aceptado')
  on conflict (publicacion_id, user_id) do update set status = 'aceptado', role = 'participante';
  update public.publicaciones set status = 'en_coordinacion' where id = p_caso_id;
end;
$$;

create or replace function public.retirar_miembro(p_caso_id uuid, p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := public.yunta_uid();
begin
  if p_user_id = v_uid then
    perform public.raise_yunta('self_action');
  end if;
  if not exists (
    select 1 from public.publicaciones
    where id = p_caso_id and author_id = v_uid and coordination_mode = 'grupal'
  ) then
    perform public.raise_yunta('forbidden');
  end if;
  update public.miembros set status = 'retirado'
  where publicacion_id = p_caso_id and user_id = p_user_id and status = 'aceptado';
  if not found then
    perform public.raise_yunta('not_found');
  end if;
end;
$$;

create or replace function public.resolver_caso(p_caso_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := public.yunta_uid();
  v_pub public.publicaciones;
begin
  select * into v_pub from public.publicaciones where id = p_caso_id;
  if not found or v_pub.kind <> 'caso' or v_pub.status not in ('abierto', 'en_coordinacion') then
    perform public.raise_yunta('conflict');
  end if;
  if v_pub.coordination_mode = 'grupal' then
    if v_pub.author_id <> v_uid then
      perform public.raise_yunta('forbidden');
    end if;
  else
    -- Cierra quien recibió la ayuda, no quien escribió el aviso.
    if not exists (
      select 1 from public.miembros receptor
      join public.miembros prestador
        on prestador.publicacion_id = receptor.publicacion_id
       and prestador.role = 'prestador'
       and prestador.status = 'aceptado'
      where receptor.publicacion_id = p_caso_id
        and receptor.role = 'receptor'
        and receptor.status = 'aceptado'
        and receptor.user_id = v_uid
    ) then
      perform public.raise_yunta('forbidden');
    end if;
  end if;
  update public.publicaciones
  set status = 'resuelto', closed_at = now()
  where id = p_caso_id;
end;
$$;

create or replace function public.cancelar_publicacion(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := public.yunta_uid();
  v_pub public.publicaciones;
begin
  select * into v_pub from public.publicaciones where id = p_id;
  if not found or v_pub.author_id <> v_uid then
    perform public.raise_yunta('forbidden');
  end if;
  if v_pub.kind = 'anuncio' then
    update public.publicaciones set status = 'retirado' where id = p_id;
    return;
  end if;
  if v_pub.status = 'resuelto' then
    perform public.raise_yunta('conflict');
  end if;
  update public.publicaciones
  set status = 'cancelado', closed_at = now()
  where id = p_id;
end;
$$;

create or replace function public.reabrir_caso(p_caso_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := public.yunta_uid();
  v_pub public.publicaciones;
  v_role text;
begin
  select * into v_pub from public.publicaciones where id = p_caso_id;
  if not found or v_pub.kind <> 'caso' or v_pub.coordination_mode <> 'individual' then
    perform public.raise_yunta('conflict');
  end if;
  if v_pub.author_id <> v_uid or v_pub.status not in ('resuelto', 'en_coordinacion') then
    perform public.raise_yunta('forbidden');
  end if;
  select role into v_role from public.miembros
  where publicacion_id = p_caso_id and user_id = v_uid;
  update public.miembros
  set status = 'retirado'
  where publicacion_id = p_caso_id
    and user_id <> v_uid
    and status = 'aceptado'
    and role is distinct from v_role;
  delete from public.valoraciones where caso_id = p_caso_id;
  update public.publicaciones
  set status = 'abierto', closed_at = null
  where id = p_caso_id;
end;
$$;

create or replace function public.editar_anuncio(p_id uuid, p_title text, p_description text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := public.yunta_uid();
  v_title text := btrim(coalesce(p_title, ''));
  v_description text := btrim(coalesce(p_description, ''));
begin
  if char_length(v_title) < 3 or char_length(v_title) > 80 or char_length(v_description) > 500 then
    perform public.raise_yunta('validation');
  end if;
  perform public.assert_public_text(v_title, v_description, '');
  update public.publicaciones
  set title = v_title, description = v_description
  where id = p_id and author_id = v_uid and kind = 'anuncio';
  if not found then
    perform public.raise_yunta('forbidden');
  end if;
end;
$$;

create or replace function public.enviar_mensaje(p_caso_id uuid, p_body text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := public.yunta_uid();
  v_body text := btrim(coalesce(p_body, ''));
  v_pub public.publicaciones;
  v_open boolean := false;
begin
  if char_length(v_body) < 1 or char_length(v_body) > 500 then
    perform public.raise_yunta('validation');
  end if;
  if (select count(*) from public.mensajes
      where sender_id = v_uid and created_at > now() - interval '5 minutes') >= 30 then
    perform public.raise_yunta('rate_limit');
  end if;
  select * into v_pub from public.publicaciones where id = p_caso_id;
  if not found or v_pub.kind <> 'caso' or v_pub.status not in ('abierto', 'en_coordinacion') then
    perform public.raise_yunta('chat_closed');
  end if;
  if not public.es_miembro_aceptado(p_caso_id, v_uid) then
    perform public.raise_yunta('chat_closed');
  end if;
  if v_pub.coordination_mode = 'individual' then
    select
      count(*) filter (where role = 'prestador') > 0
      and count(*) filter (where role = 'receptor') > 0
    into v_open
    from public.miembros
    where publicacion_id = p_caso_id and status = 'aceptado';
    if not coalesce(v_open, false) then
      perform public.raise_yunta('chat_closed');
    end if;
  end if;
  insert into public.mensajes (publicacion_id, sender_id, body)
  values (p_caso_id, v_uid, v_body);
end;
$$;

create or replace function public.recomendar(p_anuncio_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := public.yunta_uid();
  v_pub public.publicaciones;
begin
  select * into v_pub from public.publicaciones where id = p_anuncio_id;
  if not found or v_pub.kind <> 'anuncio' or v_pub.status <> 'activo' then
    perform public.raise_yunta('conflict');
  end if;
  if v_pub.author_id = v_uid then
    perform public.raise_yunta('self_action');
  end if;
  if v_pub.zone_id <> public.yunta_zone() then
    perform public.raise_yunta('zone_mismatch');
  end if;
  if public.par_bloqueado(v_uid, v_pub.author_id) then
    perform public.raise_yunta('blocked');
  end if;
  begin
    insert into public.recomendaciones (anuncio_id, user_id) values (p_anuncio_id, v_uid);
  exception
    when unique_violation then
      perform public.raise_yunta('conflict');
  end;
end;
$$;

create or replace function public.valorar(p_caso_id uuid, p_score int, p_comment text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := public.yunta_uid();
  v_pub public.publicaciones;
  v_prestador uuid;
  v_comment text := left(btrim(coalesce(p_comment, '')), 280);
begin
  if p_score is null or p_score < 1 or p_score > 5 then
    perform public.raise_yunta('validation');
  end if;
  select * into v_pub from public.publicaciones where id = p_caso_id;
  if not found or v_pub.kind <> 'caso' or v_pub.coordination_mode <> 'individual' or v_pub.status <> 'resuelto' then
    perform public.raise_yunta('conflict');
  end if;
  if not exists (
    select 1 from public.miembros
    where publicacion_id = p_caso_id and user_id = v_uid and role = 'receptor' and status = 'aceptado'
  ) then
    perform public.raise_yunta('forbidden');
  end if;
  select user_id into v_prestador from public.miembros
  where publicacion_id = p_caso_id and role = 'prestador' and status = 'aceptado';
  if v_prestador is null then
    perform public.raise_yunta('forbidden');
  end if;
  begin
    insert into public.valoraciones (caso_id, reviewer_id, reviewed_user_id, score, comment)
    values (p_caso_id, v_uid, v_prestador, p_score, v_comment);
  exception
    when unique_violation then
      perform public.raise_yunta('conflict');
  end;
end;
$$;

create or replace function public.reportar(p_target_type text, p_target_id uuid, p_reason text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := public.yunta_uid();
  v_reason text := btrim(coalesce(p_reason, ''));
  v_author uuid;
  v_sender uuid;
  v_pub uuid;
begin
  if p_target_type not in ('publicacion', 'mensaje') or char_length(v_reason) < 3 or char_length(v_reason) > 200 then
    perform public.raise_yunta('validation');
  end if;
  if p_target_type = 'publicacion' then
    select author_id into v_author from public.publicaciones where id = p_target_id;
    if v_author is null then
      perform public.raise_yunta('not_found');
    end if;
    if v_author = v_uid then
      perform public.raise_yunta('self_action');
    end if;
  else
    select sender_id, publicacion_id into v_sender, v_pub from public.mensajes where id = p_target_id;
    if v_sender is null then
      perform public.raise_yunta('not_found');
    end if;
    if v_sender = v_uid then
      perform public.raise_yunta('self_action');
    end if;
    if not public.es_miembro_aceptado(v_pub, v_uid) then
      perform public.raise_yunta('forbidden');
    end if;
  end if;
  -- El autor del aviso no tiene una función para leer quién reportó.
  insert into public.reportes (reporter_id, target_type, target_id, reason)
  values (v_uid, p_target_type, p_target_id, v_reason);
end;
$$;

create or replace function public.bloquear(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := public.yunta_uid();
begin
  if p_user_id = v_uid then
    perform public.raise_yunta('self_action');
  end if;
  if not exists (select 1 from public.profiles where user_id = p_user_id) then
    perform public.raise_yunta('not_found');
  end if;
  insert into public.bloqueos (blocker_id, blocked_id)
  values (v_uid, p_user_id)
  on conflict do nothing;
end;
$$;

create or replace function public.desbloquear(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from public.bloqueos
  where blocker_id = public.yunta_uid() and blocked_id = p_user_id;
end;
$$;

create or replace function public.listar_bloqueos()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'userId', b.blocked_id,
    'displayName', p.display_name
  )), '[]'::jsonb)
  from public.bloqueos b
  join public.profiles p on p.user_id = b.blocked_id
  where b.blocker_id = public.yunta_uid();
$$;

create or replace function public.compartir_telefono(p_caso_id uuid, p_phone text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := public.yunta_uid();
  v_phone text := regexp_replace(coalesce(p_phone, ''), '[[:space:]\(\)-]', '', 'g');
begin
  if v_phone !~ '^\+?[0-9]{8,15}$' then
    perform public.raise_yunta('validation');
  end if;
  if left(v_phone, 1) <> '+' then
    v_phone := '+' || v_phone;
  end if;
  -- Reutiliza la regla de envío: solo entra al chat si la coordinación está abierta.
  perform public.enviar_mensaje(p_caso_id, 'Mi número es ' || v_phone);
  insert into public.private_profiles (user_id, phone_e164)
  values (v_uid, v_phone)
  on conflict (user_id) do update
    set phone_e164 = excluded.phone_e164, updated_at = now();
end;
$$;
