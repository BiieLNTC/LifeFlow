create table public.categories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  description text not null,
  purpose text not null default 'both',
  color text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,

  constraint categories_description_check
    check (char_length(btrim(description)) between 1 and 80),
  constraint categories_purpose_check
    check (purpose in ('expense', 'income', 'both')),
  constraint categories_color_check
    check (color is null or color ~ '^#[0-9A-Fa-f]{6}$')
);

create unique index categories_user_description_unique
  on public.categories (user_id, lower(description))
  where deleted_at is null;

create index categories_user_purpose_idx
  on public.categories (user_id, purpose)
  where deleted_at is null;

create trigger categories_set_updated_at
before update on public.categories
for each row execute function public.set_updated_at();

alter table public.categories enable row level security;
alter table public.categories force row level security;

revoke all on table public.categories from anon, authenticated;
grant select, insert, update on table public.categories to authenticated;

create policy "categories_select_own"
on public.categories
for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "categories_insert_own"
on public.categories
for insert
to authenticated
with check ((select auth.uid()) = user_id);

create policy "categories_update_own"
on public.categories
for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

comment on table public.categories is 'Categorias financeiras do usuário (despesa, receita ou ambas).';
