begin;
select plan(6);

select has_table('public', 'transactions', 'transactions table exists');
select col_type_is('public', 'transactions', 'amount', 'numeric(14,2)', 'amount has explicit precision');

insert into auth.users(id, email)
values ('74000000-0000-0000-0000-000000000001', 'transactions@lifeflow.test');
select set_config('request.jwt.claim.sub', '74000000-0000-0000-0000-000000000001', true);
set local role authenticated;
insert into public.categories(id, description, purpose)
values ('75000000-0000-0000-0000-000000000001', 'Mercado', 'expense');

select lives_ok(
  $$insert into public.transactions(id, category_id, transaction_date, description, type, amount)
    values ('76000000-0000-0000-0000-000000000001', '75000000-0000-0000-0000-000000000001',
      current_date, 'Compra do mês', 'expense', 250)$$,
  'accepts valid transaction'
);
select throws_ok(
  $$insert into public.transactions(id, category_id, transaction_date, description, type, amount)
    values ('76000000-0000-0000-0000-000000000002', '75000000-0000-0000-0000-000000000001',
      current_date, 'Inválida', 'expense', 0)$$,
  '23514', null, 'rejects non-positive amount'
);
select throws_ok(
  $$insert into public.transactions(
      id, category_id, transaction_date, description, type, amount,
      installment_group_id, installment_index, installment_total
    ) values ('76000000-0000-0000-0000-000000000003', '75000000-0000-0000-0000-000000000001',
      current_date, 'Parcela inválida', 'expense', 100,
      gen_random_uuid(), 4, 3)$$,
  '23514', null, 'rejects installment index greater than installment total'
);
select throws_ok(
  $$update public.transactions set source_id = gen_random_uuid()
    where id = '76000000-0000-0000-0000-000000000001'$$,
  '23514', null, 'rejects source_id without source_type'
);

select * from finish();
rollback;
