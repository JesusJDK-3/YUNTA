-- Adds received rating summaries to the private profile RPC and to post
-- details the caller is already allowed to view. No policies or grants change.
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
    ), 0::numeric),
    'rating_count', (
      select count(*)::integer
      from public.ratings r
      where r.reviewed_user_id = auth.uid()
    )
  )
  from public.profiles p
  join public.private_profiles v on v.user_id = p.user_id
  join public.user_settings s on s.user_id = p.user_id
  where p.user_id = auth.uid();
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
    'author_rating_average', coalesce((
      select round(avg(r.score)::numeric, 1)
      from public.ratings r where r.reviewed_user_id = p.author_id
    ), 0::numeric),
    'author_rating_count', (
      select count(*)::integer
      from public.ratings r where r.reviewed_user_id = p.author_id
    ),
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
