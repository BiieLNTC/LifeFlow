begin;
select plan(4);

select has_table('public', 'budgets', 'budgets table exists');

insert into auth.users(id, email)
values ('77000000-0000-0000-0000-000000000001', 'budgets@lifeflow.test');
select set_config('request.jwt.claim.sub', '77000000-0000-0000-0000-000000000001', true);
set local role authenticated;
insert into public.categories(id, description, purpose)
values ('78000000-0000-0000-0000-000000000001', 'Mercado', 'expense');

select lives_ok(
  $$insert into public.budgets(id, category_id, year, month, limit_amount)
    values ('79000000-0000-0000-0000-000000000001', '78000000-0000-0000-0000-000000000001', 2026, 9, 1000)$$,
  'accepts valid budget'
);
select throws_ok(
  $$insert into public.budgets(id, category_id, year, month, limit_amount)
    values ('79000000-0000-0000-0000-000000000002', '78000000-0000-0000-0000-000000000001', 2026, 9, 500)$$,
  '23505', null, 'rejects duplicate budget for same category/month'
);
select throws_ok(
  $$insert into public.budgets(id, category_id, year, month, limit_amount)
    values ('79000000-0000-0000-0000-000000000003', '78000000-0000-0000-0000-000000000001', 2026, 13, 500)$$,
  '23514', null, 'rejects invalid month'
);

select * from finish();
rollback;
