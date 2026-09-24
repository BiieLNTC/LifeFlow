create table public.recurring_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  category_id uuid not null references public.categories (id),
  person_id uuid references public.people (id),
  description text not null,
  type text not null,
  amount numeric(14, 2) not null,
  day_of_month integer not null,
  start_date date not null,
  end_date date,
  paused boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,

  constraint recurring_transactions_description_check
    check (char_length(btrim(description)) between 1 and 160),
  constraint recurring_transactions_type_check
    check (type in ('expense', 'income')),
  constraint recurring_transactions_amount_check check (amount > 0),
  constraint recurring_transactions_day_of_month_check
    check (day_of_month between 1 and 28),
  constraint recurring_transactions_end_date_check
    check (end_date is null or end_date >= start_date)
);

create index recurring_transactions_user_active_idx
  on public.recurring_transactions (user_id, paused)
  where deleted_at is null;

create trigger recurring_transactions_set_updated_at
before update on public.recurring_transactions
for each row execute function public.set_updated_at();

alter table public.recurring_transactions enable row level security;
alter table public.recurring_transactions force row level security;

revoke all on table public.recurring_transactions from anon, authenticated;
grant select, insert, update, delete on table public.recurring_transactions to authenticated;

create policy "recurring_transactions_select_own"
on public.recurring_transactions
for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "recurring_transactions_insert_own"
on public.recurring_transactions
for insert
to authenticated
with check (
  (select auth.uid()) = user_id
  and exists (
    select 1 from public.categories
    where categories.id = recurring_transactions.category_id
      and categories.user_id = (select auth.uid())
  )
  and (
    person_id is null
    or exists (
      select 1 from public.people
      where people.id = recurring_transactions.person_id
        and people.user_id = (select auth.uid())
    )
  )
);

create policy "recurring_transactions_update_own"
on public.recurring_transactions
for update
to authenticated
using ((select auth.uid()) = user_id)
with check (
  (select auth.uid()) = user_id
  and exists (
    select 1 from public.categories
    where categories.id = recurring_transactions.category_id
      and categories.user_id = (select auth.uid())
  )
  and (
    person_id is null
    or exists (
      select 1 from public.people
      where people.id = recurring_transactions.person_id
        and people.user_id = (select auth.uid())
    )
  )
);

create policy "recurring_transactions_delete_own"
on public.recurring_transactions
for delete
to authenticated
using ((select auth.uid()) = user_id);

create function public.generate_due_recurring_transactions()
returns integer
language plpgsql
set search_path = ''
as $$
declare
  v_recurring record;
  v_month date;
  v_occurrence_date date;
  v_generated integer := 0;
begin
  for v_recurring in
    select *
    from public.recurring_transactions
    where user_id = (select auth.uid())
      and deleted_at is null
      and not paused
  loop
    for v_month in
      select generate_series(
        date_trunc('month', v_recurring.start_date)::date,
        date_trunc('month', current_date)::date,
        interval '1 month'
      )::date
    loop
      v_occurrence_date := (v_month + (v_recurring.day_of_month - 1) * interval '1 day')::date;

      if v_occurrence_date < v_recurring.start_date
        or v_occurrence_date > current_date
        or (v_recurring.end_date is not null and v_occurrence_date > v_recurring.end_date)
      then
        continue;
      end if;

      if exists (
        select 1 from public.transactions
        where source_type = 'recurring'
          and source_id = v_recurring.id
          and transaction_date = v_occurrence_date
      ) then
        continue;
      end if;

      insert into public.transactions (
        user_id, category_id, person_id, transaction_date, description,
        type, amount, source_type, source_id
      ) values (
        v_recurring.user_id, v_recurring.category_id, v_recurring.person_id,
        v_occurrence_date, v_recurring.description, v_recurring.type,
        v_recurring.amount, 'recurring', v_recurring.id
      );

      v_generated := v_generated + 1;
    end loop;
  end loop;

  return v_generated;
end;
$$;

revoke all on function public.generate_due_recurring_transactions() from public, anon;
grant execute on function public.generate_due_recurring_transactions() to authenticated;

comment on table public.recurring_transactions is
  'Modelo de transação recorrente; ocorrências são geradas sob demanda em transactions, nunca por cron.';
comment on function public.generate_due_recurring_transactions() is
  'Gera, para o usuário da sessão, as ocorrências de transações recorrentes pendentes até a data atual.';
