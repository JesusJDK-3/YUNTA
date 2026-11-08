alter table public.private_profiles
  drop constraint if exists private_profiles_area_label_check;
alter table public.posts
  drop constraint if exists posts_area_label_check;
alter table public.posts
  add constraint posts_area_label_check check (
    char_length(area_label) between 2 and 80
    and area_label !~* '([0-9#]|(^|[^[:alpha:]])(calle|avenida|av|jr|jiron|jirón|mz|manzana|lote|lt|dpto|depto|departamento|interior|int|piso|nro|numero|pasaje|psje|carretera)([^[:alpha:]]|$))'
  );
