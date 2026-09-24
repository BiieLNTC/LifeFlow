begin;
select plan(3);

select has_table('public', 'recurring_transactions', 'recurring_transactions table exists');

insert into auth.users(id, email)
values ('80000000-0000-0000-0000-000000000001', 'recurring@lifeflow.test');
select set_config('request.jwt.claim.sub', '80000000-0000-0000-0000-000000000001', true);
set local role authenticated;
insert into public.categories(id, description, purpose)
values ('81000000-0000-0000-0000-000000000001', 'Assinaturas', 'expense');

select lives_ok(
  $$insert into public.recurring_transactions(
      id, category_id, description, type, amount, day_of_month, start_date
    ) values ('82000000-0000-0000-0000-000000000001', '81000000-0000-0000-0000-000000000001',
      'Streaming', 'expense', 39.90, 5, '2026-01-05')$$,
  'accepts valid recurring transaction'
);
select throws_ok(
  $$insert into public.recurring_transactions(
      id, category_id, description, type, amount, day_of_month, start_date
    ) values ('82000000-0000-0000-0000-000000000002', '81000000-0000-0000-0000-000000000001',
      'Inválida', 'expense', 39.90, 29, '2026-01-05')$$,
  '23514', null, 'rejects day_of_month above 28'
);

select * from finish();
rollback;
