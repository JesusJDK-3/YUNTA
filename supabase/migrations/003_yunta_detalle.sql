-- Detalle del aviso y permisos.
-- Los mensajes y los pendientes solo salen si a esta persona le corresponden.
-- El reportero no tiene una vía de lectura.

create or replace function public.detalle(p_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_uid uuid := public.yunta_uid();
  v_pub public.publicaciones;
  v_my public.miembros;
  v_has_me boolean := false;
  v_in boolean := false;
  v_chat boolean := false;
  v_has_prestador boolean := false;
  v_has_receptor boolean := false;
  v_prestador uuid;
  v_receptor uuid;
  v_author_role text;
  v_opposite text;
  v_members jsonb := '[]'::jsonb;
  v_pending jsonb := '[]'::jsonb;
  v_messages jsonb := '[]'::jsonb;
  v_score int;
  v_comment text;
  v_reco boolean := false;
  v_can_join boolean := false;
begin
  select * into v_pub from public.publicaciones where id = p_id;
  if not found then
    perform public.raise_yunta('not_found');
  end if;
  if v_pub.author_id <> v_uid and exists (
    select 1 from public.bloqueos
    where blocker_id = v_uid and blocked_id = v_pub.author_id
  ) then
    perform public.raise_yunta('not_found');
  end if;

  select * into v_my from public.miembros
  where publicacion_id = p_id and user_id = v_uid;
  v_has_me := found;
  -- No leer v_my si la fila no existe: plpgsql no asigna el record.
  if v_has_me and v_my.status = 'aceptado' then
    v_in := true;
  end if;

  select exists (
    select 1 from public.miembros
    where publicacion_id = p_id and role = 'prestador' and status = 'aceptado'
  ) into v_has_prestador;
  select exists (
    select 1 from public.miembros
    where publicacion_id = p_id and role = 'receptor' and status = 'aceptado'
  ) into v_has_receptor;
  select user_id into v_prestador from public.miembros
  where publicacion_id = p_id and role = 'prestador' and status = 'aceptado' limit 1;
  select user_id into v_receptor from public.miembros
  where publicacion_id = p_id and role = 'receptor' and status = 'aceptado' limit 1;
  select role into v_author_role from public.miembros
  where publicacion_id = p_id and user_id = v_pub.author_id;

  if v_in and v_pub.kind = 'caso' and v_pub.status <> 'cancelado' then
    if v_pub.coordination_mode = 'grupal' then
      v_chat := true;
    else
      v_chat := v_has_prestador and v_has_receptor;
    end if;
  end if;

  if v_in then
    select coalesce(jsonb_agg(jsonb_build_object(
      'userId', m.user_id,
      'displayName', pr.display_name,
      'role', m.role,
      'status', m.status
    )), '[]'::jsonb)
    into v_members
    from public.miembros m
    join public.profiles pr on pr.user_id = m.user_id
    where m.publicacion_id = p_id and m.status = 'aceptado';

    select coalesce(jsonb_agg(jsonb_build_object(
      'id', msg.id,
      'senderId', msg.sender_id,
      'senderName', pr.display_name,
      'body', msg.body,
      'createdAt', msg.created_at
    ) order by msg.created_at), '[]'::jsonb)
    into v_messages
    from public.mensajes msg
    join public.profiles pr on pr.user_id = msg.sender_id
    where msg.publicacion_id = p_id;
  end if;

  if v_in then
    if v_my.role = 'receptor' then
      v_opposite := 'prestador';
    elsif v_my.role = 'prestador' then
      v_opposite := 'receptor';
    end if;
  end if;

  if v_opposite is not null then
    select coalesce(jsonb_agg(jsonb_build_object(
      'userId', m.user_id,
      'displayName', pr.display_name,
      'role', m.role,
      'status', m.status
    )), '[]'::jsonb)
    into v_pending
    from public.miembros m
    join public.profiles pr on pr.user_id = m.user_id
    where m.publicacion_id = p_id and m.status = 'pendiente' and m.role = v_opposite;
  end if;

  select exists (
    select 1 from public.recomendaciones
    where anuncio_id = p_id and user_id = v_uid
  ) into v_reco;

  select score, comment into v_score, v_comment
  from public.valoraciones
  where caso_id = p_id and reviewer_id = v_uid;

  if v_pub.coordination_mode = 'grupal'
     and v_pub.status in ('abierto', 'en_coordinacion')
     and v_pub.author_id <> v_uid
     and not v_in
     and not public.par_bloqueado(v_uid, v_pub.author_id) then
    if not v_has_me then
      v_can_join := true;
    elsif v_my.status <> 'retirado' then
      v_can_join := true;
    end if;
  end if;

  return jsonb_build_object(
    'item', public.yunta_item(v_pub, null, null),
    'members', v_members,
    'pending', v_pending,
    'messages', v_messages,
    'myRole', case when v_has_me then v_my.role else null end,
    'myStatus', case when v_has_me then v_my.status else null end,
    'isAuthor', v_pub.author_id = v_uid,
    'chatOpen', v_chat,
    'canSend', v_chat and v_pub.status in ('abierto', 'en_coordinacion'),
    'canRecommend', v_pub.kind = 'anuncio' and v_pub.status = 'activo'
      and v_pub.author_id <> v_uid and v_pub.zone_id = public.yunta_zone()
      and not v_reco and not public.par_bloqueado(v_uid, v_pub.author_id),
    'alreadyRecommended', v_reco,
    'canOfferHelp', v_pub.coordination_mode = 'individual'
      and v_pub.status in ('abierto', 'en_coordinacion')
      and not v_has_me and v_pub.author_id <> v_uid
      and v_author_role = 'receptor' and not v_has_prestador
      and not public.par_bloqueado(v_uid, v_pub.author_id),
    'canRequestHelp', v_pub.coordination_mode = 'individual'
      and v_pub.status in ('abierto', 'en_coordinacion')
      and not v_has_me and v_pub.author_id <> v_uid
      and v_author_role = 'prestador' and not v_has_receptor
      and not public.par_bloqueado(v_uid, v_pub.author_id),
    'canJoinGroup', v_can_join,
    'canResolve', v_pub.kind = 'caso' and v_pub.status in ('abierto', 'en_coordinacion') and (
      (v_pub.coordination_mode = 'grupal' and v_pub.author_id = v_uid)
      or (v_pub.coordination_mode = 'individual' and v_receptor = v_uid and v_prestador is not null)
    ),
    'canCancel', v_pub.author_id = v_uid and v_pub.status not in ('resuelto', 'retirado', 'cancelado'),
    'canReopen', v_pub.kind = 'caso' and v_pub.coordination_mode = 'individual'
      and v_pub.author_id = v_uid and v_pub.status in ('resuelto', 'en_coordinacion'),
    'canSharePhone', v_chat and v_pub.status in ('abierto', 'en_coordinacion'),
    'canEdit', v_pub.kind = 'anuncio' and v_pub.author_id = v_uid and v_pub.status = 'activo',
    'canRetire', v_pub.kind = 'anuncio' and v_pub.author_id = v_uid and v_pub.status = 'activo',
    'canRate', v_pub.kind = 'caso' and v_pub.coordination_mode = 'individual'
      and v_pub.status = 'resuelto' and v_receptor = v_uid and v_prestador is not null
      and v_score is null,
    'myRating', case
      when v_score is null then null
      else jsonb_build_object('score', v_score, 'comment', coalesce(v_comment, ''))
    end
  );
end;
$$;

drop policy if exists mensajes_select on public.mensajes;
create policy mensajes_select on public.mensajes
  for select to authenticated
  using (public.es_miembro_aceptado(publicacion_id, auth.uid()));

do $$
begin
  alter publication supabase_realtime add table public.mensajes;
exception
  when duplicate_object then null;
  when undefined_object then null;
end
$$;

revoke all on function public.raise_yunta(text) from public, anon, authenticated;
revoke all on function public.yunta_item(public.publicaciones, double precision, double precision) from public, anon, authenticated;
revoke all on function public.yunta_uid() from public, anon, authenticated;
revoke all on function public.yunta_zone() from public, anon, authenticated;
revoke all on function public.par_bloqueado(uuid, uuid) from public, anon, authenticated;
revoke all on function public.distance_label(double precision) from public, anon, authenticated;
revoke all on function public.assert_public_text(text, text, text) from public, anon, authenticated;

grant execute on function public.es_miembro_aceptado(uuid, uuid) to authenticated;
grant execute on function public.listar_zonas() to anon, authenticated;
grant execute on function public.mi_perfil() to authenticated;
grant execute on function public.guardar_perfil(text, text) to authenticated;
grant execute on function public.feed_muro(text, double precision, double precision) to authenticated;
grant execute on function public.detalle(uuid) to authenticated;
grant execute on function public.publicar(text, text, text, text, text, double precision, double precision, uuid) to authenticated;
grant execute on function public.coordinar(uuid, uuid) to authenticated;
grant execute on function public.pedir_entrada(uuid) to authenticated;
grant execute on function public.aceptar_miembro(uuid, uuid) to authenticated;
grant execute on function public.rechazar_miembro(uuid, uuid) to authenticated;
grant execute on function public.unirme(uuid) to authenticated;
grant execute on function public.retirar_miembro(uuid, uuid) to authenticated;
grant execute on function public.resolver_caso(uuid) to authenticated;
grant execute on function public.cancelar_publicacion(uuid) to authenticated;
grant execute on function public.reabrir_caso(uuid) to authenticated;
grant execute on function public.editar_anuncio(uuid, text, text) to authenticated;
grant execute on function public.enviar_mensaje(uuid, text) to authenticated;
grant execute on function public.recomendar(uuid) to authenticated;
grant execute on function public.valorar(uuid, int, text) to authenticated;
grant execute on function public.reportar(text, uuid, text) to authenticated;
grant execute on function public.bloquear(uuid) to authenticated;
grant execute on function public.desbloquear(uuid) to authenticated;
grant execute on function public.listar_bloqueos() to authenticated;
grant execute on function public.compartir_telefono(uuid, text) to authenticated;
