begin;
select plan(3);

insert into auth.users(id, email) values
  ('80000000-0000-0000-0000-000000000001', 'recurring-a@lifeflow.test'),
  ('80000000-0000-0000-0000-000000000002', 'recurring-b@lifeflow.test');

select set_config('request.jwt.claim.sub', '80000000-0000-0000-0000-000000000001', true);
set local role authenticated;
insert into public.categories(id, description, purpose)
values ('81000000-0000-0000-0000-000000000001', 'Assinaturas', 'expense');
select lives_ok(
  $$insert into public.recurring_transactions(
      id, category_id, description, type, amount, day_of_month, start_date
    ) values ('82000000-0000-0000-0000-000000000001', '81000000-0000-0000-0000-000000000001',
      'Streaming', 'expense', 39.90, 5, '2026-01-05')$$,
  'owner inserts recurring transaction'
);
select is((select count(*)::integer from public.recurring_transactions), 1, 'owner reads own recurring transaction');

reset role;
select set_config('request.jwt.claim.sub', '80000000-0000-0000-0000-000000000002', true);
set local role authenticated;
select is((select count(*)::integer from public.recurring_transactions), 0, 'other user cannot read recurring transaction');

select * from finish();
rollback;
