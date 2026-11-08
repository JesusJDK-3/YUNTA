-- Yunta: anuncio y caso.
-- El punto vive en publicaciones.geom y no se concede a la sesión del vecino.
-- La distancia sale redondeada desde distance_label. Ordenar usa el metro
-- exacto solo dentro de la función, y ese número no viaja en el JSON.
--
-- Los intentos de publicar tienen que coincidir con specFromIntent
-- en src/domain/rules.ts.

create extension if not exists pgcrypto;
create extension if not exists postgis;

create table if not exists public.zones (
  id text primary key,
  name text not null,
  center geography(point, 4326) not null
);

create table if not exists public.profiles (
  user_id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null check (char_length(display_name) between 2 and 40),
  zone_id text not null references public.zones (id),
  email text,
  created_at timestamptz not null default now()
);

create table if not exists public.private_profiles (
  user_id uuid primary key references auth.users (id) on delete cascade,
  phone_e164 text,
  updated_at timestamptz not null default now()
);

create table if not exists public.publicaciones (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles (user_id) on delete cascade,
  kind text not null check (kind in ('anuncio', 'caso')),
  category text not null,
  type text not null,
  zone_id text not null references public.zones (id),
  title text not null check (char_length(title) between 3 and 80),
  description text not null check (char_length(description) <= 500),
  coordination_mode text check (coordination_mode in ('individual', 'grupal')),
  status text not null,
  source_anuncio_id uuid references public.publicaciones (id),
  area_label text not null check (char_length(area_label) between 1 and 40),
  geom geography(point, 4326) not null,
  client_request_id uuid,
  created_at timestamptz not null default now(),
  closed_at timestamptz,
  constraint publicaciones_forma_chk check (
    (kind = 'anuncio' and status in ('activo', 'retirado') and coordination_mode is null)
    or
    (kind = 'caso' and status in ('abierto', 'en_coordinacion', 'resuelto', 'cancelado')
      and coordination_mode in ('individual', 'grupal'))
  )
);

create unique index if not exists publicaciones_client_request_idx
  on public.publicaciones (author_id, client_request_id)
  where client_request_id is not null;

create index if not exists publicaciones_zone_idx
  on public.publicaciones (zone_id, kind, status, created_at desc);

create index if not exists publicaciones_geom_idx
  on public.publicaciones using gist (geom);

create table if not exists public.miembros (
  publicacion_id uuid not null references public.publicaciones (id) on delete cascade,
  user_id uuid not null references public.profiles (user_id) on delete cascade,
  role text not null check (role in ('prestador', 'receptor', 'participante')),
  status text not null check (status in ('pendiente', 'aceptado', 'retirado')),
  joined_at timestamptz not null default now(),
  primary key (publicacion_id, user_id)
);

create index if not exists miembros_pub_idx on public.miembros (publicacion_id, status);

create table if not exists public.mensajes (
  id uuid primary key default gen_random_uuid(),
  publicacion_id uuid not null references public.publicaciones (id) on delete cascade,
  sender_id uuid not null references public.profiles (user_id) on delete cascade,
  body text not null check (char_length(body) between 1 and 500),
  created_at timestamptz not null default now()
);

create index if not exists mensajes_pub_idx
  on public.mensajes (publicacion_id, created_at);

create table if not exists public.recomendaciones (
  anuncio_id uuid not null references public.publicaciones (id) on delete cascade,
  user_id uuid not null references public.profiles (user_id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (anuncio_id, user_id)
);

create table if not exists public.valoraciones (
  caso_id uuid primary key references public.publicaciones (id) on delete cascade,
  reviewer_id uuid not null references public.profiles (user_id) on delete cascade,
  reviewed_user_id uuid not null references public.profiles (user_id) on delete cascade,
  score int not null check (score between 1 and 5),
  comment text not null default '' check (char_length(comment) <= 280),
  created_at timestamptz not null default now()
);

create index if not exists valoraciones_reviewed_idx on public.valoraciones (reviewed_user_id);

create table if not exists public.reportes (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles (user_id) on delete cascade,
  target_type text not null check (target_type in ('publicacion', 'mensaje')),
  target_id uuid not null,
  reason text not null check (char_length(reason) between 3 and 200),
  created_at timestamptz not null default now()
);

create table if not exists public.bloqueos (
  blocker_id uuid not null references public.profiles (user_id) on delete cascade,
  blocked_id uuid not null references public.profiles (user_id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);

-- Cuatro zonas del barrio. Antes del primer vecino, cambia estos centros
-- por los puntos reales de Zona Norte, Centro, Sur y Este.
insert into public.zones (id, name, center) values
  ('norte', 'Zona Norte', ST_SetSRID(ST_MakePoint(-77.040, -12.043), 4326)::geography),
  ('centro', 'Zona Centro', ST_SetSRID(ST_MakePoint(-77.040, -12.050), 4326)::geography),
  ('sur', 'Zona Sur', ST_SetSRID(ST_MakePoint(-77.040, -12.057), 4326)::geography),
  ('este', 'Zona Este', ST_SetSRID(ST_MakePoint(-77.032, -12.050), 4326)::geography)
on conflict (id) do nothing;

alter table public.zones enable row level security;
alter table public.profiles enable row level security;
alter table public.private_profiles enable row level security;
alter table public.publicaciones enable row level security;
alter table public.miembros enable row level security;
alter table public.mensajes enable row level security;
alter table public.recomendaciones enable row level security;
alter table public.valoraciones enable row level security;
alter table public.reportes enable row level security;
alter table public.bloqueos enable row level security;

-- Sin políticas de escritura para el rol authenticated.
-- Todo pasa por funciones SECURITY DEFINER. Si alguien concede un SELECT
-- de más sobre publicaciones, geom sigue sin estar en la lista de columnas.
revoke all on table public.publicaciones from anon, authenticated;
revoke all on table public.miembros from anon, authenticated;
revoke all on table public.recomendaciones from anon, authenticated;
revoke all on table public.valoraciones from anon, authenticated;
revoke all on table public.reportes from anon, authenticated;
revoke all on table public.private_profiles from anon, authenticated;
revoke all on table public.bloqueos from anon, authenticated;
revoke all on table public.profiles from anon, authenticated;

grant select on table public.mensajes to authenticated;

create or replace function public.raise_yunta(code text)
returns void
language plpgsql
as $$
begin
  raise exception 'YUNTA:%', code using errcode = 'P0001';
end;
$$;

create or replace function public.distance_label(meters double precision)
returns text
language sql
immutable
as $$
  select case
    when meters is null or meters < 0 then null
    when meters < 100 then 'A menos de 100 m'
    else 'A unos ' || (round(meters / 100.0) * 100)::int::text || ' m'
  end;
$$;

create or replace function public.es_miembro_aceptado(p_pub uuid, p_user uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.miembros
    where publicacion_id = p_pub
      and user_id = p_user
      and status = 'aceptado'
  );
$$;

create or replace function public.yunta_uid()
returns uuid
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    perform public.raise_yunta('unauthenticated');
  end if;
  return v_uid;
end;
$$;

create or replace function public.yunta_zone()
returns text
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_zone text;
begin
  select zone_id into v_zone from public.profiles where user_id = public.yunta_uid();
  if v_zone is null then
    perform public.raise_yunta('profile_required');
  end if;
  return v_zone;
end;
$$;

create or replace function public.par_bloqueado(a uuid, b uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.bloqueos
    where (blocker_id = a and blocked_id = b)
       or (blocker_id = b and blocked_id = a)
  );
$$;

-- El ítem público. El registro de la fila entra por la función;
-- latitud y longitud no se copian al JSON.
create or replace function public.yunta_item(
  p public.publicaciones,
  p_lat double precision,
  p_lng double precision
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_author text;
  v_zone text;
  v_reco int;
  v_cnt int;
  v_avg numeric;
  v_label text;
begin
  select display_name into v_author from public.profiles where user_id = p.author_id;
  select name into v_zone from public.zones where id = p.zone_id;
  select count(*)::int into v_reco from public.recomendaciones where anuncio_id = p.id;
  select count(*)::int, avg(score)::numeric into v_cnt, v_avg
  from public.valoraciones
  where reviewed_user_id = p.author_id;

  if p_lat is not null and p_lng is not null then
    v_label := public.distance_label(
      ST_Distance(p.geom, ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography)
    );
  end if;

  return jsonb_build_object(
    'id', p.id,
    'kind', p.kind,
    'category', p.category,
    'type', p.type,
    'title', p.title,
    'description', p.description,
    'zoneId', p.zone_id,
    'zoneName', v_zone,
    'areaLabel', p.area_label,
    'distanceLabel', v_label,
    'coordinationMode', p.coordination_mode,
    'status', p.status,
    'recommendationCount', case when p.kind = 'anuncio' then coalesce(v_reco, 0) else 0 end,
    'ratingCount', case when p.kind = 'anuncio' and coalesce(v_cnt, 0) >= 3 then v_cnt else 0 end,
    'ratingAverage', case when p.kind = 'anuncio' and coalesce(v_cnt, 0) >= 3 then round(v_avg, 1) else null end,
    'authorId', p.author_id,
    'authorName', coalesce(v_author, 'Vecino'),
    'sourceAnuncioId', p.source_anuncio_id,
    'createdAt', p.created_at
  );
end;
$$;

create or replace function public.listar_zonas()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    jsonb_agg(jsonb_build_object('id', id, 'name', name) order by name),
    '[]'::jsonb
  )
  from public.zones;
$$;

create or replace function public.mi_perfil()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'userId', p.user_id,
    'displayName', p.display_name,
    'zoneId', p.zone_id,
    'zoneName', z.name
  )
  from public.profiles p
  join public.zones z on z.id = p.zone_id
  where p.user_id = auth.uid();
$$;

create or replace function public.guardar_perfil(p_name text, p_zone_id text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := public.yunta_uid();
  v_name text := btrim(coalesce(p_name, ''));
begin
  if char_length(v_name) < 2 or char_length(v_name) > 40 then
    perform public.raise_yunta('validation');
  end if;
  if not exists (select 1 from public.zones where id = p_zone_id) then
    perform public.raise_yunta('validation');
  end if;
  insert into public.profiles (user_id, display_name, zone_id, email)
  values (v_uid, v_name, p_zone_id, auth.jwt() ->> 'email')
  on conflict (user_id) do update
    set display_name = excluded.display_name,
        zone_id = excluded.zone_id,
        email = excluded.email;
end;
$$;

create or replace function public.feed_muro(
  p_tab text,
  p_lat double precision,
  p_lng double precision
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_uid uuid := public.yunta_uid();
  v_zone text := public.yunta_zone();
  v_point geography;
  v_items jsonb;
begin
  if p_tab not in ('ayuda', 'servicios', 'emergencias') then
    perform public.raise_yunta('validation');
  end if;
  if (p_lat is null) <> (p_lng is null) then
    perform public.raise_yunta('validation');
  end if;
  if p_lat is not null and (p_lat < -90 or p_lat > 90 or p_lng < -180 or p_lng > 180) then
    perform public.raise_yunta('validation');
  end if;
  if p_lat is not null then
    v_point := ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography;
  end if;

  if p_tab = 'emergencias' and v_point is null then
    select coalesce(jsonb_agg(public.yunta_item(s::public.publicaciones, null, null) order by s.created_at desc), '[]'::jsonb)
      into v_items
    from (
      select p.*
      from public.publicaciones p
      where (
          p.kind = 'anuncio'
          and p.category = 'grupo_de_apoyo'
          and p.zone_id = v_zone
          and p.status = 'activo'
          or (
            p.kind = 'caso'
            and p.category = 'grupo_de_apoyo'
            and p.status in ('abierto', 'en_coordinacion')
            and exists (
              select 1 from public.miembros m
              where m.publicacion_id = p.id
                and m.user_id = v_uid
                and m.status in ('pendiente', 'aceptado')
            )
          )
        )
        and not exists (
          select 1 from public.bloqueos b
          where b.blocker_id = v_uid and b.blocked_id = p.author_id
        )
      order by p.created_at desc
      limit 40
    ) s;
    return jsonb_build_object('items', v_items, 'needsLocation', true);
  end if;

  -- sort_key no sale del JSON: es el metro exacto y solo ordena.
  select coalesce(jsonb_agg(s.item order by s.sort_key, s.created_at desc), '[]'::jsonb)
  into v_items
  from (
    select
      public.yunta_item(p, p_lat, p_lng) as item,
      case when v_point is null then 0 else ST_Distance(p.geom, v_point) end as sort_key,
      p.created_at
    from public.publicaciones p
    where not exists (
        select 1 from public.bloqueos b
        where b.blocker_id = v_uid and b.blocked_id = p.author_id
      )
      and (
        (p_tab = 'ayuda' and p.kind = 'caso' and p.category = 'ayuda' and p.zone_id = v_zone
          and p.status in ('abierto', 'en_coordinacion'))
        or
        (p_tab = 'servicios' and (
          (p.kind = 'anuncio' and p.category in ('producto', 'servicio')
            and p.zone_id = v_zone and p.status = 'activo')
          or
          (p.kind = 'caso' and p.category in ('producto', 'servicio')
            and p.status in ('abierto', 'en_coordinacion')
            and exists (
              select 1 from public.miembros m
              where m.publicacion_id = p.id and m.user_id = v_uid and m.status in ('pendiente', 'aceptado')
            ))
        ))
        or
        (p_tab = 'emergencias' and (
          (p.kind = 'anuncio' and p.category = 'grupo_de_apoyo' and p.zone_id = v_zone and p.status = 'activo')
          or
          (p.kind = 'caso' and p.category = 'grupo_de_apoyo'
            and p.status in ('abierto', 'en_coordinacion')
            and exists (
              select 1 from public.miembros m
              where m.publicacion_id = p.id and m.user_id = v_uid and m.status in ('pendiente', 'aceptado')
            ))
          or
          (p.kind = 'caso' and p.category = 'emergencia' and p.status in ('abierto', 'en_coordinacion')
            and v_point is not null and ST_DWithin(p.geom, v_point, 500))
        ))
      )
    order by 2 asc, p.created_at desc
    limit 40
  ) s;

  return jsonb_build_object('items', v_items, 'needsLocation', false);
end;
$$;
