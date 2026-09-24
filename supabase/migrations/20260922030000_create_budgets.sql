create table public.budgets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  category_id uuid not null references public.categories (id),
  year integer not null,
  month integer not null,
  limit_amount numeric(14, 2) not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,

  constraint budgets_year_check check (year between 2000 and 2100),
  constraint budgets_month_check check (month between 1 and 12),
  constraint budgets_limit_amount_check check (limit_amount > 0)
);

create unique index budgets_user_category_month_unique
  on public.budgets (user_id, category_id, year, month)
  where deleted_at is null;

create trigger budgets_set_updated_at
before update on public.budgets
for each row execute function public.set_updated_at();

alter table public.budgets enable row level security;
alter table public.budgets force row level security;

revoke all on table public.budgets from anon, authenticated;
grant select, insert, update, delete on table public.budgets to authenticated;

create policy "budgets_select_own"
on public.budgets
for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "budgets_insert_own"
on public.budgets
for insert
to authenticated
with check (
  (select auth.uid()) = user_id
  and exists (
    select 1 from public.categories
    where categories.id = budgets.category_id
      and categories.user_id = (select auth.uid())
  )
);

create policy "budgets_update_own"
on public.budgets
for update
to authenticated
using ((select auth.uid()) = user_id)
with check (
  (select auth.uid()) = user_id
  and exists (
    select 1 from public.categories
    where categories.id = budgets.category_id
      and categories.user_id = (select auth.uid())
  )
);

create policy "budgets_delete_own"
on public.budgets
for delete
to authenticated
using ((select auth.uid()) = user_id);

comment on table public.budgets is 'Orçamento mensal do usuário por categoria.';
