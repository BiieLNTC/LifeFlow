begin;
select plan(7);

select has_view('public', 'finance_totals', 'finance_totals view exists');
select has_view('public', 'budget_progress', 'budget_progress view exists');
select has_view('public', 'finance_monthly_evolution', 'finance_monthly_evolution view exists');

insert into auth.users(id, email)
values ('95000000-0000-0000-0000-000000000001', 'views@lifeflow.test');
select set_config('request.jwt.claim.sub', '95000000-0000-0000-0000-000000000001', true);
set local role authenticated;
insert into public.categories(id, description, purpose)
values ('96000000-0000-0000-0000-000000000001', 'Mercado', 'expense');
insert into public.budgets(id, category_id, year, month, limit_amount)
values (
  '97000000-0000-0000-0000-000000000001', '96000000-0000-0000-0000-000000000001',
  extract(year from current_date)::int, extract(month from current_date)::int, 1000
);
insert into public.transactions(id, category_id, transaction_date, description, type, amount) values
  ('98000000-0000-0000-0000-000000000001', '96000000-0000-0000-0000-000000000001', current_date, 'Compra 1', 'expense', 600),
  ('98000000-0000-0000-0000-000000000002', '96000000-0000-0000-0000-000000000001', current_date, 'Compra 2', 'expense', 300),
  ('98000000-0000-0000-0000-000000000003', '96000000-0000-0000-0000-000000000001', current_date, 'Salário', 'income', 5000);

select is(
  (select monthly_expense from public.finance_totals), 900.00::numeric,
  'sums monthly expenses across transactions'
);
select is(
  (select balance from public.finance_totals), 4100.00::numeric,
  'balance nets all-time income against expenses'
);
select is(
  (select status from public.budget_progress where budget_id = '97000000-0000-0000-0000-000000000001'),
  'warning', 'budget progress flags warning between 80% and 99%'
);
select is(
  (select count(*)::integer from public.finance_monthly_evolution), 12,
  'evolution view always returns the trailing twelve months'
);

select * from finish();
rollback;
