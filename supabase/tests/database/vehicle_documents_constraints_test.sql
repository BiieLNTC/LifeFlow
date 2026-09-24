begin;
select plan(4);

select has_table('public', 'vehicle_documents', 'vehicle_documents table exists');

insert into auth.users(id, email)
values ('89000000-0000-0000-0000-000000000001', 'documents@lifeflow.test');
select set_config('request.jwt.claim.sub', '89000000-0000-0000-0000-000000000001', true);
set local role authenticated;
insert into public.vehicles(id, vehicle_type, nickname, brand, model)
values ('90000000-0000-0000-0000-000000000001', 'car', 'Carro', 'Marca', 'Modelo');

select lives_ok(
  $$insert into public.vehicle_documents(id, vehicle_id, type, description, issue_date, expiry_date)
    values ('91000000-0000-0000-0000-000000000001', '90000000-0000-0000-0000-000000000001',
      'insurance', 'Seguro anual', current_date - 30, current_date + 335)$$,
  'accepts valid vehicle document'
);
select throws_ok(
  $$insert into public.vehicle_documents(id, vehicle_id, type, description, issue_date, expiry_date)
    values ('91000000-0000-0000-0000-000000000002', '90000000-0000-0000-0000-000000000001',
      'licensing', 'Datas invertidas', current_date, current_date - 1)$$,
  '23514', null, 'rejects expiry date before issue date'
);
select throws_ok(
  $$insert into public.vehicle_documents(id, vehicle_id, type, description)
    values ('91000000-0000-0000-0000-000000000003', '90000000-0000-0000-0000-000000000001',
      'other', '')$$,
  '23514', null, 'rejects empty description'
);

select * from finish();
rollback;
