begin;
select plan(3);

insert into auth.users(id, email) values
  ('77000000-0000-0000-0000-000000000001', 'budgets-a@lifeflow.test'),
  ('77000000-0000-0000-0000-000000000002', 'budgets-b@lifeflow.test');

select set_config('request.jwt.claim.sub', '77000000-0000-0000-0000-000000000001', true);
set local role authenticated;
insert into public.categories(id, description, purpose)
values ('78000000-0000-0000-0000-000000000001', 'Mercado', 'expense');
select lives_ok(
  $$insert into public.budgets(id, category_id, year, month, limit_amount)
    values ('79000000-0000-0000-0000-000000000001', '78000000-0000-0000-0000-000000000001', 2026, 9, 1000)$$,
  'owner inserts budget'
);
select is((select count(*)::integer from public.budgets), 1, 'owner reads own budget');

reset role;
select set_config('request.jwt.claim.sub', '77000000-0000-0000-0000-000000000002', true);
set local role authenticated;
select is((select count(*)::integer from public.budgets), 0, 'other user cannot read budget');

select * from finish();
rollback;
