begin;
select plan(3);

insert into auth.users(id, email) values
  ('92000000-0000-0000-0000-000000000001', 'trips-a@lifeflow.test'),
  ('92000000-0000-0000-0000-000000000002', 'trips-b@lifeflow.test');

select set_config('request.jwt.claim.sub', '92000000-0000-0000-0000-000000000001', true);
set local role authenticated;
insert into public.vehicles(id, vehicle_type, nickname, brand, model)
values ('93000000-0000-0000-0000-000000000001', 'car', 'Carro', 'Marca', 'Modelo');
select lives_ok(
  $$insert into public.trips(id, vehicle_id, start_odometer, started_at)
    values ('94000000-0000-0000-0000-000000000001', '93000000-0000-0000-0000-000000000001', 1000, now())$$,
  'owner inserts trip'
);
select is((select count(*)::integer from public.trips), 1, 'owner reads own trip');

reset role;
select set_config('request.jwt.claim.sub', '92000000-0000-0000-0000-000000000002', true);
set local role authenticated;
select is((select count(*)::integer from public.trips), 0, 'other user cannot read trip');

select * from finish();
rollback;
