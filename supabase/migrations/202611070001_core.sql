create extension if not exists postgis with schema extensions;

create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(display_name) between 2 and 60),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.private_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  phone_e164 text not null check (phone_e164 ~ '^\+[1-9][0-9]{7,14}$'),
  phone_verified_at timestamptz,
  area_label text not null check (char_length(area_label) between 2 and 80 and area_label !~* '([0-9#]|(^|[^[:alpha:]])(calle|avenida|av|jr|jiron|jirón|mz|manzana|lote|lt|dpto|depto|departamento|interior|int|piso|nro|numero)([^[:alpha:]]|$))'),
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  location_source text not null check (location_source in ('gps', 'manual')),
  updated_at timestamptz not null default now()
);

create table if not exists public.user_settings (
  user_id uuid primary key references auth.users(id) on delete cascade,
  tutorial_completed_at timestamptz,
  updated_at timestamptz not null default now()
);

create table if not exists public.posts (
  id uuid primary key,
  author_id uuid not null references auth.users(id) on delete cascade,
  category text not null check (category in ('help', 'products_services', 'emergency')),
  type text not null check (type in ('help_request', 'help_offer', 'product', 'service', 'urgent_request', 'resource_available', 'support_group_available')),
  title text not null check (char_length(title) between 4 and 100),
  description text not null check (char_length(description) between 8 and 1200),
  coordination_mode text not null check (coordination_mode in ('individual', 'group')),
  status text not null default 'open' check (status in ('open', 'coordinating', 'resolved', 'cancelled')),
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  location extensions.geography(point, 4326) generated always as (
    extensions.st_setsrid(extensions.st_makepoint(longitude, latitude), 4326)::extensions.geography
  ) stored,
  area_label text not null check (char_length(area_label) between 2 and 80 and area_label !~* '([0-9#]|(^|[^[:alpha:]])(calle|avenida|av|jr|jiron|jirón|mz|manzana|lote|lt|dpto|depto|departamento|interior|int|piso|nro|numero)([^[:alpha:]]|$))'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  closed_at timestamptz,
  check (
    (category = 'help' and type in ('help_request', 'help_offer')) or
    (category = 'products_services' and type in ('product', 'service')) or
    (category = 'emergency' and type in ('urgent_request', 'resource_available', 'support_group_available'))
  ),
  check (type <> 'support_group_available' or coordination_mode = 'group')
);

create table if not exists public.post_members (
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('author', 'provider', 'recipient', 'participant')),
  status text not null check (status in ('pending', 'accepted', 'active', 'released')),
  joined_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create unique index if not exists one_accepted_individual_member
  on public.post_members(post_id) where status = 'accepted';
create index if not exists posts_location_idx on public.posts using gist(location);
create index if not exists posts_open_created_idx on public.posts(status, created_at desc);
create index if not exists members_user_idx on public.post_members(user_id, status);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 2000),
  created_at timestamptz not null default now()
);
create index if not exists messages_post_created_idx on public.messages(post_id, created_at);

create table if not exists public.recommendations (
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create table if not exists public.ratings (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  reviewer_id uuid not null references auth.users(id) on delete cascade,
  reviewed_user_id uuid not null references auth.users(id) on delete cascade,
  score smallint not null check (score between 1 and 5),
  comment text check (comment is null or char_length(comment) <= 500),
  created_at timestamptz not null default now(),
  unique (post_id, reviewer_id),
  check (reviewer_id <> reviewed_user_id)
);

create or replace function public.bootstrap_yunta_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles(user_id, display_name)
  values (new.id, coalesce(nullif(new.raw_user_meta_data ->> 'display_name', ''), 'Vecino'))
  on conflict (user_id) do nothing;
  insert into public.user_settings(user_id) values (new.id) on conflict do nothing;
  return new;
end;
$$;

drop trigger if exists yunta_user_created on auth.users;
create trigger yunta_user_created after insert on auth.users
for each row execute function public.bootstrap_yunta_user();

create or replace function public.can_access_post(p_post_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.posts p
    where p.id = p_post_id and p.status <> 'cancelled'
      and (p.author_id = auth.uid() or exists (
        select 1 from public.post_members m
        where m.post_id = p.id and m.user_id = auth.uid()
          and m.status in ('accepted', 'active')
      ))
  );
$$;

create or replace function public.can_send_message(p_post_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.posts p where p.id = p_post_id
      and p.status in ('open', 'coordinating') and public.can_access_post(p.id)
  );
$$;

alter table public.profiles enable row level security;
alter table public.private_profiles enable row level security;
alter table public.user_settings enable row level security;
alter table public.posts enable row level security;
alter table public.post_members enable row level security;
alter table public.messages enable row level security;
alter table public.recommendations enable row level security;
alter table public.ratings enable row level security;

create policy messages_read_access on public.messages for select to authenticated using (public.can_access_post(post_id));
create policy messages_insert_access on public.messages for insert to authenticated
  with check (sender_id = auth.uid() and public.can_send_message(post_id));
revoke all on public.private_profiles, public.posts, public.post_members from anon, authenticated;
revoke all on public.profiles, public.user_settings, public.private_profiles, public.recommendations, public.ratings from anon, authenticated;
revoke all on public.messages from anon;
grant select, insert on public.messages to authenticated;
revoke all on function public.can_access_post(uuid) from public;
grant execute on function public.can_access_post(uuid) to authenticated;
revoke all on function public.can_send_message(uuid) from public;
grant execute on function public.can_send_message(uuid) to authenticated;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'messages'
  ) then
    alter publication supabase_realtime add table public.messages;
  end if;
end $$;
