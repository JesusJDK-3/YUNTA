-- Quita marcas que no son texto del barrio, también si alguien llama
-- la función con la anon key y se salta el cliente.
-- $ < > / \ { } ` |

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
  v := translate(v, '$<>/{}`|' || chr(92), '');
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

revoke all on function public.sanitize_plain(text, integer) from public, anon, authenticated;

-- El celular escondido entre $ o / se revisa ya limpio, igual que el texto que se guarda.
create or replace function public.assert_public_text(p_title text, p_description text, p_area text)
returns void
language plpgsql
as $$
declare
  v_title text := public.sanitize_plain(p_title, 80);
  v_description text := public.sanitize_plain(p_description, 500);
  v_area text := public.sanitize_plain(p_area, 40);
  v_text text := concat_ws(E'\n', v_title, v_description);
begin
  if v_text ~ '(\+?[0-9][0-9[:space:]().-]{7,}[0-9])' then
    perform public.raise_yunta('private_text');
  end if;
  if concat_ws(E'\n', v_text, v_area) ~* '(calle|avenida|jir[oó]n|manzana|pasaje|departamento)[^[:cntrl:]]{0,40}[0-9]{1,5}' then
    perform public.raise_yunta('private_text');
  end if;
end;
$$;

revoke all on function public.assert_public_text(text, text, text) from public, anon, authenticated;
