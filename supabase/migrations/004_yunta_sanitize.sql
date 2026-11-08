-- Limpia el texto al guardarlo, aunque el cliente no lo haya hecho.
-- Misma idea que cleanText en src/domain/rules.ts.

create or replace function public.sanitize_plain(p_value text, p_max integer)
returns text
language plpgsql
immutable
as $$
declare
  v text := coalesce(p_value, '');
begin
  v := regexp_replace(v, '<\s*(script|style)\b[^>]*>[\s\S]*?</\s*\1\s*>', ' ', 'gi');
  v := regexp_replace(v, '<[^>]*>', ' ', 'g');
  v := regexp_replace(v, '[[:cntrl:]]', '', 'g');
  v := replace(v, chr(8203), '');
  v := replace(v, chr(8204), '');
  v := replace(v, chr(8205), '');
  v := replace(v, chr(65279), '');
  v := regexp_replace(v, '[[:space:]]+', ' ', 'g');
  v := btrim(v);
  if p_max > 0 and char_length(v) > p_max then
    v := left(v, p_max);
  end if;
  return v;
end;
$$;

create or replace function public.sanitize_written_text()
returns trigger
language plpgsql
as $$
begin
  if tg_table_name = 'publicaciones' then
    new.title := public.sanitize_plain(new.title, 80);
    new.description := public.sanitize_plain(new.description, 500);
    new.area_label := public.sanitize_plain(new.area_label, 40);
    if char_length(new.title) < 3 or char_length(new.area_label) < 1 then
      perform public.raise_yunta('validation');
    end if;
  elsif tg_table_name = 'mensajes' then
    new.body := public.sanitize_plain(new.body, 500);
    if char_length(new.body) < 1 then
      perform public.raise_yunta('validation');
    end if;
  elsif tg_table_name = 'profiles' then
    new.display_name := public.sanitize_plain(new.display_name, 40);
    if char_length(new.display_name) < 2
       or new.display_name !~ '[[:alpha:]]'
       or new.display_name ~ '[0-9@<>]' then
      perform public.raise_yunta('validation');
    end if;
  elsif tg_table_name = 'reportes' then
    new.reason := public.sanitize_plain(new.reason, 200);
    if char_length(new.reason) < 3 then
      perform public.raise_yunta('validation');
    end if;
  elsif tg_table_name = 'valoraciones' then
    new.comment := public.sanitize_plain(new.comment, 280);
  end if;
  return new;
end;
$$;

drop trigger if exists publicaciones_sanitize on public.publicaciones;
create trigger publicaciones_sanitize
before insert or update of title, description, area_label on public.publicaciones
for each row execute function public.sanitize_written_text();

drop trigger if exists mensajes_sanitize on public.mensajes;
create trigger mensajes_sanitize
before insert or update of body on public.mensajes
for each row execute function public.sanitize_written_text();

drop trigger if exists profiles_sanitize on public.profiles;
create trigger profiles_sanitize
before insert or update of display_name on public.profiles
for each row execute function public.sanitize_written_text();

drop trigger if exists reportes_sanitize on public.reportes;
create trigger reportes_sanitize
before insert or update of reason on public.reportes
for each row execute function public.sanitize_written_text();

drop trigger if exists valoraciones_sanitize on public.valoraciones;
create trigger valoraciones_sanitize
before insert or update of comment on public.valoraciones
for each row execute function public.sanitize_written_text();

revoke all on function public.sanitize_plain(text, integer) from public, anon, authenticated;
revoke all on function public.sanitize_written_text() from public, anon, authenticated;
