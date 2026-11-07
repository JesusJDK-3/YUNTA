alter table public.private_profiles
  drop constraint if exists private_profiles_area_label_check;

drop function if exists public.save_my_profile(text, text, text, double precision, double precision, text, boolean);

alter table public.private_profiles
  drop column if exists area_label;

create or replace function public.save_my_profile(
  p_display_name text,
  p_phone_e164 text,
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
  if p_latitude not between -90 and 90 or p_longitude not between -180 and 180 then raise exception 'Ubicación inválida.'; end if;
  if p_location_source not in ('gps', 'manual') then raise exception 'Origen de ubicación inválido.'; end if;
  insert into public.profiles(user_id, display_name)
  values (auth.uid(), trim(p_display_name))
  on conflict (user_id) do update set display_name = excluded.display_name, updated_at = now();
  insert into public.private_profiles(user_id, phone_e164, latitude, longitude, location_source)
  values (auth.uid(), p_phone_e164, p_latitude, p_longitude, p_location_source)
  on conflict (user_id) do update set phone_e164 = excluded.phone_e164, latitude = excluded.latitude,
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
    'display_name', p.display_name, 'phone_e164', v.phone_e164,
    'latitude', v.latitude, 'longitude', v.longitude,
    'location_source', v.location_source, 'tutorial_completed_at', s.tutorial_completed_at
  )
  from public.profiles p
  join public.private_profiles v on v.user_id = p.user_id
  join public.user_settings s on s.user_id = p.user_id
  where p.user_id = auth.uid();
$$;

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
  perform public.save_my_profile(
    p_display_name, p_phone_e164, p_latitude, p_longitude, p_location_source, p_tutorial_completed
  );
end;
$$;

revoke all on function public.save_my_profile(text, text, double precision, double precision, text, boolean) from public;
grant execute on function public.save_my_profile(text, text, double precision, double precision, text, boolean) to authenticated;
revoke all on function public.save_my_profile(text, text, text, double precision, double precision, text, boolean) from public;
grant execute on function public.save_my_profile(text, text, text, double precision, double precision, text, boolean) to authenticated;
revoke all on function public.get_my_profile() from public;
grant execute on function public.get_my_profile() to authenticated;
