create table if not exists public.push_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  fid text not null unique,
  platform text not null check (platform in ('android')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists push_tokens_user_idx
  on public.push_tokens(user_id);

alter table public.push_tokens enable row level security;
revoke all on public.push_tokens from anon, authenticated;
grant select, insert, update, delete on public.push_tokens to authenticated;

drop policy if exists push_tokens_read_own on public.push_tokens;
create policy push_tokens_read_own on public.push_tokens
  for select to authenticated using (user_id = auth.uid());
drop policy if exists push_tokens_insert_own on public.push_tokens;
create policy push_tokens_insert_own on public.push_tokens
  for insert to authenticated with check (user_id = auth.uid());
drop policy if exists push_tokens_update_own on public.push_tokens;
create policy push_tokens_update_own on public.push_tokens
  for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists push_tokens_delete_own on public.push_tokens;
create policy push_tokens_delete_own on public.push_tokens
  for delete to authenticated using (user_id = auth.uid());
