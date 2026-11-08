create or replace function public.block_private_post_text()
returns trigger language plpgsql set search_path = '' as $$
begin
  if concat_ws(' ', new.title, new.description) ~* '(\+?[0-9][0-9[:space:]().-]{7,}[0-9]|(^|[^[:alpha:]])(calle|cal|avenida|av|jr|jiron|jirón|mz|manzana|lote|lt|dpto|depto|departamento|interior|int|piso|nro|numero|pasaje|psje|carretera|camino[[:space:]]+(real|de(l|[[:space:]]+(los?|las?))?))([^[:alpha:]]|$)[^.!?\n]{0,120}[0-9]{1,5}|(^|[^0-9])[0-9]{1,5}[[:space:]]*,?[[:space:]]*(calle|cal|avenida|av|jr|jiron|jirón|pasaje|psje|carretera|camino[[:space:]]+(real|de(l|[[:space:]]+(los?|las?))?))([^[:alpha:]]|$))' then
    raise exception 'No publiques celulares ni direcciones exactas; compártelos en el chat.';
  end if;
  if new.area_label ~* '(^|[^[:alpha:]])camino[[:space:]]+(real|de(l|[[:space:]]+(los?|las?))?)([^[:alpha:]]|$)' then
    raise exception 'Usa solo un nombre de zona aproximada, sin nombre de calle.';
  end if;
  return new;
end;
$$;

drop trigger if exists posts_block_private_text on public.posts;
create trigger posts_block_private_text
before insert or update of title, description, area_label on public.posts
for each row execute function public.block_private_post_text();
