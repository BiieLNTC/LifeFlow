create table public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  category_id uuid not null references public.categories (id),
  person_id uuid references public.people (id),
  transaction_date date not null,
  description text not null,
  type text not null,
  amount numeric(14, 2) not null,
  source_type text,
  source_id uuid,
  installment_group_id uuid,
  installment_index integer,
  installment_total integer,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,

  constraint transactions_description_check
    check (char_length(btrim(description)) between 1 and 160),
  constraint transactions_type_check
    check (type in ('expense', 'income')),
  constraint transactions_amount_check check (amount > 0),
  constraint transactions_source_type_check
    check (
      source_type is null
      or source_type in ('maintenance', 'refueling', 'vehicle_expense', 'recurring')
    ),
  constraint transactions_source_pair_check
    check ((source_type is null) = (source_id is null)),
  constraint transactions_installment_check
    check (
      (installment_group_id is null and installment_index is null and installment_total is null)
      or (
        installment_group_id is not null
        and installment_total > 0
        and installment_index between 1 and installment_total
      )
    )
);

create index transactions_user_date_idx
  on public.transactions (user_id, transaction_date desc, created_at desc)
  where deleted_at is null;

-- One mirrored transaction per origin record for 1:1 sources (maintenance/refueling/vehicle_expense).
create unique index transactions_maintenance_source_unique
  on public.transactions (source_id)
  where source_type = 'maintenance';

create unique index transactions_refueling_source_unique
  on public.transactions (source_id)
  where source_type = 'refueling';

create unique index transactions_vehicle_expense_source_unique
  on public.transactions (source_id)
  where source_type = 'vehicle_expense';

-- Recurring transactions are 1:many (one model generates one occurrence per due month).
create unique index transactions_recurring_occurrence_unique
  on public.transactions (source_id, transaction_date)
  where source_type = 'recurring';

create index transactions_installment_group_idx
  on public.transactions (installment_group_id)
  where installment_group_id is not null;

create trigger transactions_set_updated_at
before update on public.transactions
for each row execute function public.set_updated_at();

alter table public.transactions enable row level security;
alter table public.transactions force row level security;

revoke all on table public.transactions from anon, authenticated;
grant select, insert, update, delete on table public.transactions to authenticated;

create policy "transactions_select_own"
on public.transactions
for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "transactions_insert_own"
on public.transactions
for insert
to authenticated
with check (
  (select auth.uid()) = user_id
  and exists (
    select 1 from public.categories
    where categories.id = transactions.category_id
      and categories.user_id = (select auth.uid())
  )
  and (
    person_id is null
    or exists (
      select 1 from public.people
      where people.id = transactions.person_id
        and people.user_id = (select auth.uid())
    )
  )
);

create policy "transactions_update_own"
on public.transactions
for update
to authenticated
using ((select auth.uid()) = user_id and source_type is null)
with check (
  (select auth.uid()) = user_id
  and source_type is null
  and exists (
    select 1 from public.categories
    where categories.id = transactions.category_id
      and categories.user_id = (select auth.uid())
  )
  and (
    person_id is null
    or exists (
      select 1 from public.people
      where people.id = transactions.person_id
        and people.user_id = (select auth.uid())
    )
  )
);

create policy "transactions_delete_own"
on public.transactions
for delete
to authenticated
using ((select auth.uid()) = user_id and source_type is null);

comment on table public.transactions is 'Transações financeiras do usuário, manuais ou espelhadas a partir de veículos/recorrências.';
comment on column public.transactions.source_type is
  'Origem quando gerada automaticamente; não editável/excluível pelo client de finanças (ver RLS).';
