-- Keep existing individual help assignments as providers and let only the
-- request author rate the accepted neighbor who helped.
update public.post_members member
set role = 'provider', updated_at = now()
from public.posts post
where post.id = member.post_id
  and post.type in ('help_request', 'urgent_request')
  and post.coordination_mode = 'individual'
  and post.status in ('coordinating', 'resolved')
  and member.user_id <> post.author_id
  and member.status = 'accepted'
  and member.role = 'participant';

-- Historical builds could leave a reversed rating attached to an accepted
-- member whose role was still the generic participant role.
update public.post_members member
set role = 'provider', updated_at = now()
from public.posts post, public.ratings rating
where post.id = member.post_id
  and rating.post_id = post.id
  and rating.reviewer_id = member.user_id
  and rating.reviewed_user_id = post.author_id
  and post.type in ('help_request', 'urgent_request')
  and post.coordination_mode = 'individual'
  and member.status in ('accepted', 'released')
  and member.role = 'participant';

-- Preserve at most one usable rating per request and repair its direction.
with reversed_ratings as (
  select rating.id, rating.post_id, rating.created_at,
    post.author_id as reviewer_id,
    member.user_id as reviewed_user_id,
    row_number() over (
      partition by rating.post_id order by rating.created_at desc, rating.id
    ) as rating_rank
  from public.ratings rating
  join public.posts post on post.id = rating.post_id
  join public.post_members member on member.post_id = post.id
    and member.user_id = rating.reviewer_id
  where post.type in ('help_request', 'urgent_request')
    and post.coordination_mode = 'individual'
    and member.role = 'provider'
    and member.status in ('accepted', 'released')
    and rating.reviewed_user_id = post.author_id
)
update public.ratings rating
set counts_toward_profile = false
from reversed_ratings reversed
where rating.id = reversed.id and reversed.rating_rank > 1;

with reversed_ratings as (
  select rating.id, rating.post_id, rating.created_at,
    post.author_id as reviewer_id,
    member.user_id as reviewed_user_id,
    row_number() over (
      partition by rating.post_id order by rating.created_at desc, rating.id
    ) as rating_rank
  from public.ratings rating
  join public.posts post on post.id = rating.post_id
  join public.post_members member on member.post_id = post.id
    and member.user_id = rating.reviewer_id
  where post.type in ('help_request', 'urgent_request')
    and post.coordination_mode = 'individual'
    and member.role = 'provider'
    and member.status in ('accepted', 'released')
    and rating.reviewed_user_id = post.author_id
)
update public.ratings rating
set counts_toward_profile = false
from reversed_ratings reversed
where rating.id = reversed.id
  and reversed.rating_rank = 1
  and exists (
    select 1 from public.ratings existing
    where existing.post_id = rating.post_id
      and existing.reviewer_id = reversed.reviewer_id
      and existing.id <> rating.id
  );

with reversed_ratings as (
  select rating.id, rating.post_id, rating.created_at,
    post.author_id as reviewer_id,
    member.user_id as reviewed_user_id,
    row_number() over (
      partition by rating.post_id order by rating.created_at desc, rating.id
    ) as rating_rank
  from public.ratings rating
  join public.posts post on post.id = rating.post_id
  join public.post_members member on member.post_id = post.id
    and member.user_id = rating.reviewer_id
  where post.type in ('help_request', 'urgent_request')
    and post.coordination_mode = 'individual'
    and member.role = 'provider'
    and member.status in ('accepted', 'released')
    and rating.reviewed_user_id = post.author_id
)
update public.ratings rating
set reviewer_id = reversed.reviewer_id,
    reviewed_user_id = reversed.reviewed_user_id,
    counts_toward_profile = true
from reversed_ratings reversed
where rating.id = reversed.id
  and reversed.rating_rank = 1
  and not exists (
    select 1 from public.ratings existing
    where existing.post_id = rating.post_id
      and existing.reviewer_id = reversed.reviewer_id
      and existing.id <> rating.id
  )
  and not exists (
    select 1 from public.ratings existing
    where existing.post_id = rating.post_id
      and existing.counts_toward_profile
      and existing.id <> rating.id
  );

create or replace function public.rate_provider(
  p_post_id uuid,
  p_score smallint,
  p_comment text default null
)
returns uuid language plpgsql security definer set search_path = '' as $$
declare
  v_post public.posts%rowtype;
  v_reviewer uuid;
  v_provider uuid;
  v_rating uuid;
begin
  if auth.uid() is null or auth.role() <> 'authenticated' then
    raise exception 'Debes iniciar sesión.';
  end if;
  select * into v_post from public.posts where id = p_post_id;
  if v_post.id is null or v_post.status <> 'resolved'
    or v_post.coordination_mode <> 'individual' then
    raise exception 'La valoración está disponible al resolver un caso individual.';
  end if;
  if p_score is null or p_score not between 1 and 5
    or char_length(coalesce(p_comment, '')) > 500 then
    raise exception 'Revisa la valoración.';
  end if;

  if v_post.type in ('help_request', 'urgent_request') then
    v_reviewer := v_post.author_id;
    select member.user_id into v_provider
    from public.post_members member
    where member.post_id = p_post_id
      and member.role = 'provider'
      and member.status = 'accepted';
    if auth.uid() is distinct from v_post.author_id then
      raise exception 'Solo quien publicó puede calificar al vecino que ayudó.';
    end if;
  else
    select member.user_id into v_reviewer
    from public.post_members member
    where member.post_id = p_post_id
      and member.role = 'recipient'
      and member.status = 'accepted';
    v_provider := v_post.author_id;
    if auth.uid() is distinct from v_reviewer then
      raise exception 'Solo quien recibió el servicio puede calificarlo.';
    end if;
  end if;

  if v_provider is null or v_provider = v_reviewer then
    raise exception 'No hay una persona aceptada que pueda recibir esta calificación.';
  end if;
  if exists (
    select 1 from public.ratings rating
    where rating.post_id = p_post_id and rating.counts_toward_profile
  ) then
    raise exception 'Este caso ya tiene una valoración.';
  end if;
  insert into public.ratings(post_id, reviewer_id, reviewed_user_id, score, comment)
  values (
    p_post_id, v_reviewer, v_provider, p_score,
    nullif(trim(p_comment), '')
  )
  returning id into v_rating;
  return v_rating;
end;
$$;

revoke all on function public.rate_provider(uuid, smallint, text) from public;
grant execute on function public.rate_provider(uuid, smallint, text) to authenticated;
