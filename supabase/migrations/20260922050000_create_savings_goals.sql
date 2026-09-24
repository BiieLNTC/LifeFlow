create table public.savings_goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  title text not null,
  target_amount numeric(14, 2) not null,
  target_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,

  constraint savings_goals_title_check
    check (char_length(btrim(title)) between 1 and 120),
  constraint savings_goals_target_amount_check check (target_amount > 0)
);

create index savings_goals_user_active_idx
  on public.savings_goals (user_id)
  where deleted_at is null;

create trigger savings_goals_set_updated_at
before update on public.savings_goals
for each row execute function public.set_updated_at();

alter table public.savings_goals enable row level security;
alter table public.savings_goals force row level security;

revoke all on table public.savings_goals from anon, authenticated;
grant select, insert, update, delete on table public.savings_goals to authenticated;

create policy "savings_goals_select_own"
on public.savings_goals
for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "savings_goals_insert_own"
on public.savings_goals
for insert
to authenticated
with check ((select auth.uid()) = user_id);

create policy "savings_goals_update_own"
on public.savings_goals
for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create policy "savings_goals_delete_own"
on public.savings_goals
for delete
to authenticated
using ((select auth.uid()) = user_id);

create table public.goal_contributions (
  id uuid primary key default gen_random_uuid(),
  goal_id uuid not null references public.savings_goals (id) on delete cascade,
  transaction_id uuid references public.transactions (id),
  amount numeric(14, 2) not null,
  contribution_date date not null,
  created_at timestamptz not null default now(),

  constraint goal_contributions_amount_check check (amount > 0),
  constraint goal_contributions_date_check check (contribution_date <= current_date)
);

create index goal_contributions_goal_idx
  on public.goal_contributions (goal_id, contribution_date desc);

alter table public.goal_contributions enable row level security;
alter table public.goal_contributions force row level security;

revoke all on table public.goal_contributions from anon, authenticated;
grant select, insert, update, delete on table public.goal_contributions to authenticated;

create policy "goal_contributions_select_own"
on public.goal_contributions
for select
to authenticated
using (
  exists (
    select 1 from public.savings_goals
    where savings_goals.id = goal_contributions.goal_id
      and savings_goals.user_id = (select auth.uid())
  )
);

create policy "goal_contributions_insert_own"
on public.goal_contributions
for insert
to authenticated
with check (
  exists (
    select 1 from public.savings_goals
    where savings_goals.id = goal_contributions.goal_id
      and savings_goals.user_id = (select auth.uid())
  )
  and (
    transaction_id is null
    or exists (
      select 1 from public.transactions
      where transactions.id = goal_contributions.transaction_id
        and transactions.user_id = (select auth.uid())
    )
  )
);

create policy "goal_contributions_update_own"
on public.goal_contributions
for update
to authenticated
using (
  exists (
    select 1 from public.savings_goals
    where savings_goals.id = goal_contributions.goal_id
      and savings_goals.user_id = (select auth.uid())
  )
)
with check (
  exists (
    select 1 from public.savings_goals
    where savings_goals.id = goal_contributions.goal_id
      and savings_goals.user_id = (select auth.uid())
  )
  and (
    transaction_id is null
    or exists (
      select 1 from public.transactions
      where transactions.id = goal_contributions.transaction_id
        and transactions.user_id = (select auth.uid())
    )
  )
);

create policy "goal_contributions_delete_own"
on public.goal_contributions
for delete
to authenticated
using (
  exists (
    select 1 from public.savings_goals
    where savings_goals.id = goal_contributions.goal_id
      and savings_goals.user_id = (select auth.uid())
  )
);

comment on table public.savings_goals is 'Metas de poupança do usuário.';
comment on table public.goal_contributions is
  'Aportes registrados para uma meta, opcionalmente ligados a uma transação de despesa.';
