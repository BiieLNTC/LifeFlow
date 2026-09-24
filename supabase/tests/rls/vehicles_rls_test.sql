begin;

select plan(7);

insert into auth.users (id, email)
values
  ('10000000-0000-0000-0000-000000000001', 'owner-a@motora.test'),
  ('10000000-0000-0000-0000-000000000002', 'owner-b@motora.test');

select set_config('request.jwt.claim.sub', '10000000-0000-0000-0000-000000000001', true);
set local role authenticated;

select lives_ok(
  $$
    insert into public.vehicles (id, vehicle_type, nickname, brand, model)
    values ('20000000-0000-0000-0000-000000000001', 'car', 'Carro A', 'Marca', 'Modelo')
  $$,
  'owner can create a vehicle'
);

select is(
  (select user_id::text from public.vehicles where id = '20000000-0000-0000-0000-000000000001'),
  '10000000-0000-0000-0000-000000000001',
  'user_id defaults to auth.uid()'
);

select is((select count(*)::integer from public.vehicles), 1, 'owner can read own vehicle');

reset role;
select set_config('request.jwt.claim.sub', '10000000-0000-0000-0000-000000000002', true);
set local role authenticated;

select is((select count(*)::integer from public.vehicles), 0, 'another user cannot read the vehicle');

select lives_ok(
  $$ update public.vehicles set nickname = 'Invadido' where id = '20000000-0000-0000-0000-000000000001' $$,
  'hidden rows cannot be updated by another user'
);

reset role;
select set_config('request.jwt.claim.sub', '10000000-0000-0000-0000-000000000001', true);
set local role authenticated;

select is(
  (select nickname from public.vehicles where id = '20000000-0000-0000-0000-000000000001'),
  'Carro A',
  'cross-user update changed no data'
);

select ok(
  not has_table_privilege('authenticated', 'public.vehicles', 'DELETE'),
  'hard delete is not granted to clients'
);

select * from finish();
rollback;
