alter table public.ratings
  add column if not exists counts_toward_profile boolean not null default true;

create or replace function public.update_my_location(
  p_latitude double precision,
  p_longitude double precision,
  p_location_source text
)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null or auth.role() <> 'authenticated' then
    raise exception 'Debes iniciar sesión.';
  end if;
  if p_latitude is null or p_longitude is null
    or p_latitude < -90 or p_latitude > 90
    or p_longitude < -180 or p_longitude > 180 then
    raise exception 'Ubicación inválida.';
  end if;
  if p_location_source not in ('gps', 'manual') then
    raise exception 'Origen de ubicación inválido.';
  end if;
  update public.private_profiles
  set latitude = p_latitude,
      longitude = p_longitude,
      location_source = p_location_source,
      updated_at = now()
  where user_id = auth.uid();
  if not found then raise exception 'No se encontró tu perfil.'; end if;
end;
$$;

create or replace function public.rate_provider(
  p_post_id uuid,
  p_score smallint,
  p_comment text default null
)
returns uuid language plpgsql security definer set search_path = '' as $$
declare
  v_post public.posts%rowtype;
  v_receiver uuid;
  v_provider uuid;
  v_rating uuid;
begin
  if auth.uid() is null or auth.role() <> 'authenticated' then
    raise exception 'Debes iniciar sesión.';
  end if;
  select * into v_post
  from public.posts
  where id = p_post_id;
  if v_post.id is null or v_post.status <> 'resolved'
    or v_post.coordination_mode <> 'individual' then
    raise exception 'La valoración está disponible al resolver un caso individual.';
  end if;
  if p_score is null or p_score not between 1 and 5
    or char_length(coalesce(p_comment, '')) > 500 then
    raise exception 'Revisa la valoración.';
  end if;

  if v_post.type in ('help_request', 'urgent_request') then
    v_receiver := v_post.author_id;
    select member.user_id into v_provider
    from public.post_members member
    where member.post_id = p_post_id
      and member.role = 'provider'
      and member.status = 'accepted';
  else
    select member.user_id into v_receiver
    from public.post_members member
    where member.post_id = p_post_id
      and member.role = 'recipient'
      and member.status = 'accepted';
    v_provider := v_post.author_id;
  end if;

  if v_receiver is distinct from auth.uid()
    or v_provider is null or v_provider = v_receiver then
    raise exception 'Solo quien recibió la ayuda puede valorar a quien la prestó.';
  end if;
  if exists (
    select 1 from public.ratings rating
    where rating.post_id = p_post_id and rating.counts_toward_profile
  ) then
    raise exception 'Este caso ya tiene una valoración.';
  end if;
  insert into public.ratings(post_id, reviewer_id, reviewed_user_id, score, comment)
  values (
    p_post_id, v_receiver, v_provider, p_score,
    nullif(trim(p_comment), '')
  )
  returning id into v_rating;
  return v_rating;
end;
$$;

create or replace function public.get_my_profile()
returns jsonb language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'display_name', p.display_name,
    'phone_e164', v.phone_e164,
    'latitude', v.latitude,
    'longitude', v.longitude,
    'location_source', v.location_source,
    'tutorial_completed_at', s.tutorial_completed_at,
    'rating_average', coalesce((
      select round(avg(r.score)::numeric, 1)
      from public.ratings r
      where r.reviewed_user_id = auth.uid()
        and r.counts_toward_profile
    ), 0::numeric),
    'rating_count', (
      select count(*)::integer
      from public.ratings r
      where r.reviewed_user_id = auth.uid()
        and r.counts_toward_profile
    )
  )
  from public.profiles p
  join public.private_profiles v on v.user_id = p.user_id
  join public.user_settings s on s.user_id = p.user_id
  where p.user_id = auth.uid();
$$;

create or replace function public.get_post_detail(p_post_id uuid)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare v_result jsonb;
begin
  select jsonb_build_object(
    'id', p.id,
    'category', p.category,
    'type', p.type,
    'title', p.title,
    'description', p.description,
    'coordination_mode', p.coordination_mode,
    'status', p.status,
    'area_label', p.area_label,
    'created_at', p.created_at,
    'author_id', p.author_id,
    'author_name', author.display_name,
    'author_rating_average', coalesce((
      select round(avg(r.score)::numeric, 1)
      from public.ratings r where r.reviewed_user_id = p.author_id
        and r.counts_toward_profile
    ), 0::numeric),
    'author_rating_count', (
      select count(*)::integer
      from public.ratings r where r.reviewed_user_id = p.author_id
        and r.counts_toward_profile
    ),
    'provider_name', case
      when p.status = 'resolved' and p.coordination_mode = 'individual' and (
        (auth.uid() = p.author_id and p.type in ('help_request', 'urgent_request'))
        or (auth.uid() <> p.author_id
          and p.type not in ('help_request', 'urgent_request')
          and exists (
            select 1 from public.post_members recipient
            where recipient.post_id = p.id
              and recipient.user_id = auth.uid()
              and recipient.role = 'recipient'
              and recipient.status = 'accepted'
          ))
      ) then case when p.type in ('help_request', 'urgent_request') then (
        select provider.display_name
        from public.post_members accepted
        join public.profiles provider on provider.user_id = accepted.user_id
        where accepted.post_id = p.id
          and accepted.role = 'provider'
          and accepted.status = 'accepted'
      ) else author.display_name end
      else null end,
    'can_rate', p.status = 'resolved'
      and p.coordination_mode = 'individual'
      and not exists (
        select 1 from public.ratings r
        where r.post_id = p.id and r.counts_toward_profile
      )
      and (
        (p.type in ('help_request', 'urgent_request')
          and auth.uid() = p.author_id
          and exists (
            select 1 from public.post_members provider
            where provider.post_id = p.id
              and provider.role = 'provider'
              and provider.status = 'accepted'
          ))
        or (p.type not in ('help_request', 'urgent_request')
          and auth.uid() <> p.author_id
          and exists (
            select 1 from public.post_members recipient
            where recipient.post_id = p.id
              and recipient.user_id = auth.uid()
              and recipient.role = 'recipient'
              and recipient.status = 'accepted'
          ))
      ),
    'distance_m', round(extensions.st_distance(
      p.location,
      extensions.st_setsrid(
        extensions.st_makepoint(me.longitude, me.latitude), 4326
      )::extensions.geography
    ) / 10.0)::integer * 10,
    'member_count', (
      select count(*)::integer from public.post_members member
      where member.post_id = p.id and member.user_id <> p.author_id
        and member.status in ('active', 'accepted')
    ),
    'recommendation_count', (
      select count(*) from public.recommendations recommendation
      where recommendation.post_id = p.id
    ),
    'has_recommended', exists (
      select 1 from public.recommendations recommendation
      where recommendation.post_id = p.id and recommendation.user_id = auth.uid()
    ),
    'my_rating', (
      select r.id from public.ratings r
      where r.post_id = p.id and r.reviewer_id = auth.uid()
        and r.counts_toward_profile
    ),
    'my_membership', (
      select member.status from public.post_members member
      where member.post_id = p.id and member.user_id = auth.uid()
    ),
    'offers', case when p.author_id = auth.uid() then (
      select coalesce(jsonb_agg(jsonb_build_object(
        'user_id', member.user_id,
        'display_name', profile.display_name,
        'joined_at', member.joined_at
      )), '[]'::jsonb)
      from public.post_members member
      join public.profiles profile on profile.user_id = member.user_id
      where member.post_id = p.id and member.status = 'pending'
    ) else '[]'::jsonb end
  ) into v_result
  from public.posts p
  join public.profiles author on author.user_id = p.author_id
  join public.private_profiles me on me.user_id = auth.uid()
  where p.id = p_post_id and (
    p.author_id = auth.uid()
    or (p.status in ('open', 'coordinating') and extensions.st_dwithin(
      p.location,
      extensions.st_setsrid(
        extensions.st_makepoint(me.longitude, me.latitude), 4326
      )::extensions.geography,
      500
    ))
    or public.can_access_post(p.id)
  );
  if v_result is null then
    raise exception 'El aviso no está disponible cerca de ti.';
  end if;
  return v_result;
end;
$$;

with reversed_ratings as (
  select rating.id, rating.post_id, rating.created_at,
    post.author_id as reviewer_id,
    member.user_id as reviewed_user_id
  from public.ratings rating
  join public.posts post on post.id = rating.post_id
  join public.post_members member on member.post_id = post.id
    and member.user_id = rating.reviewer_id
  where post.coordination_mode = 'individual'
    and post.type in ('help_request', 'urgent_request')
    and member.role = 'provider'
    and member.status in ('accepted', 'released')
    and rating.reviewed_user_id = post.author_id
  union all
  select rating.id, rating.post_id, rating.created_at,
    member.user_id as reviewer_id,
    post.author_id as reviewed_user_id
  from public.ratings rating
  join public.posts post on post.id = rating.post_id
  join public.post_members member on member.post_id = post.id
    and member.user_id = rating.reviewed_user_id
  where post.coordination_mode = 'individual'
    and post.type not in ('help_request', 'urgent_request')
    and member.role = 'recipient'
    and member.status in ('accepted', 'released')
    and rating.reviewer_id = post.author_id
), ranked_reversals as (
  select reversed.*,
    row_number() over (
      partition by reversed.post_id, reversed.reviewer_id
      order by reversed.created_at desc, reversed.id
    ) as reversal_rank
  from reversed_ratings reversed
)
update public.ratings rating
set counts_toward_profile = false
from ranked_reversals reversed
where rating.id = reversed.id
  and (reversed.reversal_rank > 1 or exists (
    select 1 from public.ratings existing
    where existing.post_id = rating.post_id
      and existing.reviewer_id = reversed.reviewer_id
      and existing.id <> rating.id
  ));

with reversed_ratings as (
  select rating.id, rating.post_id, rating.created_at,
    post.author_id as reviewer_id,
    member.user_id as reviewed_user_id
  from public.ratings rating
  join public.posts post on post.id = rating.post_id
  join public.post_members member on member.post_id = post.id
    and member.user_id = rating.reviewer_id
  where post.coordination_mode = 'individual'
    and post.type in ('help_request', 'urgent_request')
    and member.role = 'provider'
    and member.status in ('accepted', 'released')
    and rating.reviewed_user_id = post.author_id
  union all
  select rating.id, rating.post_id, rating.created_at,
    member.user_id as reviewer_id,
    post.author_id as reviewed_user_id
  from public.ratings rating
  join public.posts post on post.id = rating.post_id
  join public.post_members member on member.post_id = post.id
    and member.user_id = rating.reviewed_user_id
  where post.coordination_mode = 'individual'
    and post.type not in ('help_request', 'urgent_request')
    and member.role = 'recipient'
    and member.status in ('accepted', 'released')
    and rating.reviewer_id = post.author_id
), ranked_reversals as (
  select reversed.*,
    row_number() over (
      partition by reversed.post_id, reversed.reviewer_id
      order by reversed.created_at desc, reversed.id
    ) as reversal_rank
  from reversed_ratings reversed
)
update public.ratings rating
set reviewer_id = reversed.reviewer_id,
    reviewed_user_id = reversed.reviewed_user_id
from ranked_reversals reversed
where rating.id = reversed.id
  and reversed.reversal_rank = 1
  and not exists (
    select 1 from public.ratings existing
    where existing.post_id = rating.post_id
      and existing.reviewer_id = reversed.reviewer_id
      and existing.id <> rating.id
  );

with ranked_case_ratings as (
  select rating.id,
    row_number() over (
      partition by rating.post_id
      order by rating.counts_toward_profile desc,
        rating.created_at desc, rating.id
    ) as case_rank
  from public.ratings rating
)
update public.ratings rating
set counts_toward_profile = false
from ranked_case_ratings ranked
where rating.id = ranked.id and ranked.case_rank > 1;

create unique index if not exists ratings_one_profile_rating_per_post
  on public.ratings(post_id) where counts_toward_profile;

revoke all on function public.update_my_location(double precision, double precision, text) from public;
revoke all on function public.update_my_location(double precision, double precision, text) from anon;
grant execute on function public.update_my_location(double precision, double precision, text) to authenticated;
revoke all on function public.rate_provider(uuid, smallint, text) from public;
grant execute on function public.rate_provider(uuid, smallint, text) to authenticated;
revoke all on function public.get_my_profile() from public;
grant execute on function public.get_my_profile() to authenticated;
revoke all on function public.get_post_detail(uuid) from public;
grant execute on function public.get_post_detail(uuid) to authenticated;
