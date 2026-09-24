create table public.people (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  name text not null,
  birth_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,

  constraint people_name_check
    check (char_length(btrim(name)) between 1 and 120),
  constraint people_birth_date_check
    check (birth_date is null or birth_date <= current_date)
);

create index people_user_active_idx
  on public.people (user_id, name)
  where deleted_at is null;

create trigger people_set_updated_at
before update on public.people
for each row execute function public.set_updated_at();

alter table public.people enable row level security;
alter table public.people force row level security;

revoke all on table public.people from anon, authenticated;
grant select, insert, update on table public.people to authenticated;

create policy "people_select_own"
on public.people
for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "people_insert_own"
on public.people
for insert
to authenticated
with check ((select auth.uid()) = user_id);

create policy "people_update_own"
on public.people
for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

comment on table public.people is 'Pessoas vinculadas às transações financeiras do usuário.';
