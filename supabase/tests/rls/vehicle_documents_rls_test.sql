begin;
select plan(3);

insert into auth.users(id, email) values
  ('89000000-0000-0000-0000-000000000001', 'documents-a@lifeflow.test'),
  ('89000000-0000-0000-0000-000000000002', 'documents-b@lifeflow.test');

select set_config('request.jwt.claim.sub', '89000000-0000-0000-0000-000000000001', true);
set local role authenticated;
insert into public.vehicles(id, vehicle_type, nickname, brand, model)
values ('90000000-0000-0000-0000-000000000001', 'car', 'Carro', 'Marca', 'Modelo');
select lives_ok(
  $$insert into public.vehicle_documents(id, vehicle_id, type, description, expiry_date)
    values ('91000000-0000-0000-0000-000000000001', '90000000-0000-0000-0000-000000000001',
      'insurance', 'Seguro anual', current_date + 335)$$,
  'owner inserts vehicle document'
);
select is((select count(*)::integer from public.vehicle_documents), 1, 'owner reads own vehicle document');

reset role;
select set_config('request.jwt.claim.sub', '89000000-0000-0000-0000-000000000002', true);
set local role authenticated;
select is((select count(*)::integer from public.vehicle_documents), 0, 'other user cannot read vehicle document');

select * from finish();
rollback;
