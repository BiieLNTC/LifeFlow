create table public.expenses (
  id uuid primary key,
  vehicle_id uuid not null references public.vehicles (id) on delete cascade,
  category text not null,
  expense_date date not null,
  amount numeric(14, 2) not null,
  description text not null,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  last_synced_at timestamptz,

  constraint expenses_category_check check (category in (
    'fuel', 'maintenance', 'insurance', 'ipva', 'licensing', 'fine',
    'toll', 'parking', 'car_wash', 'accessories', 'tires', 'other'
  )),
  constraint expenses_amount_check check (amount > 0),
  constraint expenses_description_check
    check (char_length(btrim(description)) between 1 and 160),
  constraint expenses_notes_check check (notes is null or char_length(notes) <= 2000)
);

create index expenses_vehicle_date_idx
  on public.expenses (vehicle_id, expense_date desc, created_at desc)
  where deleted_at is null;

create trigger expenses_set_updated_at
before update on public.expenses
for each row execute function public.set_updated_at();

alter table public.expenses enable row level security;
alter table public.expenses force row level security;
revoke all on table public.expenses from anon, authenticated;
grant select, insert, update on table public.expenses to authenticated;

create policy "expenses_select_own" on public.expenses
for select to authenticated using (
  exists (select 1 from public.vehicles
    where vehicles.id = expenses.vehicle_id
      and vehicles.user_id = (select auth.uid()))
);
create policy "expenses_insert_own" on public.expenses
for insert to authenticated with check (
  exists (select 1 from public.vehicles
    where vehicles.id = expenses.vehicle_id
      and vehicles.user_id = (select auth.uid())
      and vehicles.deleted_at is null)
);
create policy "expenses_update_own" on public.expenses
for update to authenticated
using (exists (select 1 from public.vehicles
  where vehicles.id = expenses.vehicle_id and vehicles.user_id = (select auth.uid())))
with check (exists (select 1 from public.vehicles
  where vehicles.id = expenses.vehicle_id and vehicles.user_id = (select auth.uid())));

create view public.financial_entries
with (security_invoker = true)
as
select id, vehicle_id, refueling_date as entry_date, total_amount as amount,
  'fuel'::text as category, 'refueling'::text as source,
  'Abastecimento'::text as description
from public.refuelings where deleted_at is null
union all
select id, vehicle_id, maintenance_date, total_amount,
  'maintenance'::text, 'maintenance'::text,
  'Manutenção'::text
from public.maintenances where deleted_at is null
union all
select id, vehicle_id, expense_date, amount,
  category, 'expense'::text, description
from public.expenses where deleted_at is null;

revoke all on public.financial_entries from anon, authenticated;
grant select on public.financial_entries to authenticated;
comment on view public.financial_entries is 'Fonte financeira consolidada sem replicar abastecimentos ou manutenções em expenses.';
