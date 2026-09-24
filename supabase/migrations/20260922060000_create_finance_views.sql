create view public.finance_totals
with (security_invoker = true)
as
select
  coalesce(sum(amount) filter (where type = 'income'), 0)::numeric(14, 2)
    - coalesce(sum(amount) filter (where type = 'expense'), 0)::numeric(14, 2)
    as balance,
  coalesce(sum(amount) filter (
    where type = 'income'
      and transaction_date >= date_trunc('month', current_date)::date
      and transaction_date < (date_trunc('month', current_date) + interval '1 month')::date
  ), 0)::numeric(14, 2) as monthly_income,
  coalesce(sum(amount) filter (
    where type = 'expense'
      and transaction_date >= date_trunc('month', current_date)::date
      and transaction_date < (date_trunc('month', current_date) + interval '1 month')::date
  ), 0)::numeric(14, 2) as monthly_expense
from public.transactions
where deleted_at is null;

revoke all on public.finance_totals from anon, authenticated;
grant select on public.finance_totals to authenticated;
comment on view public.finance_totals is
  'Saldo total (todas as transações) e receitas/despesas do mês corrente do usuário.';

create view public.finance_totals_by_category
with (security_invoker = true)
as
select
  categories.id as category_id,
  categories.description as category_description,
  categories.color as category_color,
  transactions.type,
  sum(transactions.amount)::numeric(14, 2) as total_amount,
  count(*)::integer as transaction_count
from public.transactions
join public.categories on categories.id = transactions.category_id
where transactions.deleted_at is null
group by categories.id, categories.description, categories.color, transactions.type;

revoke all on public.finance_totals_by_category from anon, authenticated;
grant select on public.finance_totals_by_category to authenticated;
comment on view public.finance_totals_by_category is 'Totais de receita/despesa agrupados por categoria.';

create view public.finance_totals_by_person
with (security_invoker = true)
as
select
  people.id as person_id,
  people.name as person_name,
  transactions.type,
  sum(transactions.amount)::numeric(14, 2) as total_amount,
  count(*)::integer as transaction_count
from public.transactions
join public.people on people.id = transactions.person_id
where transactions.deleted_at is null
group by people.id, people.name, transactions.type;

revoke all on public.finance_totals_by_person from anon, authenticated;
grant select on public.finance_totals_by_person to authenticated;
comment on view public.finance_totals_by_person is 'Totais de receita/despesa agrupados por pessoa vinculada.';

create view public.finance_top_expenses
with (security_invoker = true)
as
select
  transactions.id,
  transactions.transaction_date,
  transactions.description,
  transactions.amount,
  transactions.category_id,
  categories.description as category_description,
  row_number() over (order by transactions.amount desc, transactions.transaction_date desc) as rank
from public.transactions
join public.categories on categories.id = transactions.category_id
where transactions.deleted_at is null
  and transactions.type = 'expense'
  and transactions.transaction_date >= date_trunc('month', current_date)::date
  and transactions.transaction_date < (date_trunc('month', current_date) + interval '1 month')::date
order by transactions.amount desc, transactions.transaction_date desc
limit 10;

revoke all on public.finance_top_expenses from anon, authenticated;
grant select on public.finance_top_expenses to authenticated;
comment on view public.finance_top_expenses is 'Maiores despesas do mês corrente do usuário (top 10).';

create view public.finance_top_income
with (security_invoker = true)
as
select
  transactions.id,
  transactions.transaction_date,
  transactions.description,
  transactions.amount,
  transactions.category_id,
  categories.description as category_description,
  row_number() over (order by transactions.amount desc, transactions.transaction_date desc) as rank
from public.transactions
join public.categories on categories.id = transactions.category_id
where transactions.deleted_at is null
  and transactions.type = 'income'
  and transactions.transaction_date >= date_trunc('month', current_date)::date
  and transactions.transaction_date < (date_trunc('month', current_date) + interval '1 month')::date
order by transactions.amount desc, transactions.transaction_date desc
limit 10;

revoke all on public.finance_top_income from anon, authenticated;
grant select on public.finance_top_income to authenticated;
comment on view public.finance_top_income is 'Maiores receitas do mês corrente do usuário (top 10).';

create view public.budget_progress
with (security_invoker = true)
as
select
  budgets.id as budget_id,
  budgets.user_id,
  budgets.category_id,
  categories.description as category_description,
  budgets.year,
  budgets.month,
  budgets.limit_amount,
  coalesce(spent.total_amount, 0)::numeric(14, 2) as spent_amount,
  case
    when budgets.limit_amount > 0 then
      round(coalesce(spent.total_amount, 0) / budgets.limit_amount * 100, 2)
    else null
  end as percentage,
  case
    when coalesce(spent.total_amount, 0) >= budgets.limit_amount then 'critical'
    when coalesce(spent.total_amount, 0) >= budgets.limit_amount * 0.8 then 'warning'
    else 'normal'
  end as status
from public.budgets
left join public.categories on categories.id = budgets.category_id
left join lateral (
  select sum(transactions.amount) as total_amount
  from public.transactions
  where transactions.category_id = budgets.category_id
    and transactions.user_id = budgets.user_id
    and transactions.type = 'expense'
    and transactions.deleted_at is null
    and extract(year from transactions.transaction_date)::int = budgets.year
    and extract(month from transactions.transaction_date)::int = budgets.month
) as spent on true
where budgets.deleted_at is null;

revoke all on public.budget_progress from anon, authenticated;
grant select on public.budget_progress to authenticated;
comment on view public.budget_progress is
  'Progresso de cada orçamento mensal: gasto real, percentual e status (normal/warning/critical).';

create view public.finance_monthly_evolution
with (security_invoker = true)
as
with months as (
  select generate_series(
    date_trunc('month', current_date) - interval '11 months',
    date_trunc('month', current_date),
    interval '1 month'
  )::date as month
)
select
  months.month,
  coalesce(sum(transactions.amount) filter (where transactions.type = 'income'), 0)::numeric(14, 2)
    as income,
  coalesce(sum(transactions.amount) filter (where transactions.type = 'expense'), 0)::numeric(14, 2)
    as expense
from months
left join public.transactions
  on date_trunc('month', transactions.transaction_date)::date = months.month
  and transactions.deleted_at is null
group by months.month
order by months.month;

revoke all on public.finance_monthly_evolution from anon, authenticated;
grant select on public.finance_monthly_evolution to authenticated;
comment on view public.finance_monthly_evolution is
  'Receitas e despesas mensais do usuário nos últimos 12 meses, com meses sem lançamento zerados.';
