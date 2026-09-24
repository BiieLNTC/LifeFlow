begin;
select plan(5);

insert into auth.users(id, email) values
  ('74000000-0000-0000-0000-000000000001', 'transactions-a@lifeflow.test'),
  ('74000000-0000-0000-0000-000000000002', 'transactions-b@lifeflow.test');

select set_config('request.jwt.claim.sub', '74000000-0000-0000-0000-000000000001', true);
set local role authenticated;
insert into public.categories(id, description, purpose)
values ('75000000-0000-0000-0000-000000000001', 'Mercado', 'expense');
select lives_ok(
  $$insert into public.transactions(id, category_id, transaction_date, description, type, amount)
    values ('76000000-0000-0000-0000-000000000001', '75000000-0000-0000-0000-000000000001',
      current_date, 'Compra', 'expense', 100)$$,
  'owner inserts transaction with own category'
);
select is((select count(*)::integer from public.transactions), 1, 'owner reads own transaction');

reset role;
select set_config('request.jwt.claim.sub', '74000000-0000-0000-0000-000000000002', true);
set local role authenticated;
select is((select count(*)::integer from public.transactions), 0, 'other user cannot read transaction');
select throws_ok(
  $$insert into public.transactions(id, category_id, transaction_date, description, type, amount)
    values ('76000000-0000-0000-0000-000000000002', '75000000-0000-0000-0000-000000000001',
      current_date, 'Roubo', 'expense', 50)$$,
  null, null, 'other user cannot use someone else''s category'
);

reset role;
select set_config('request.jwt.claim.sub', '74000000-0000-0000-0000-000000000001', true);
set local role authenticated;
select is((select count(*)::integer from public.transactions), 1, 'owner category was not used by other user');

select * from finish();
rollback;
