begin;
select plan(6);

select has_table('public', 'trips', 'trips table exists');

insert into auth.users(id, email)
values ('92000000-0000-0000-0000-000000000001', 'trips@lifeflow.test');
select set_config('request.jwt.claim.sub', '92000000-0000-0000-0000-000000000001', true);
set local role authenticated;
insert into public.vehicles(id, vehicle_type, nickname, brand, model, current_odometer)
values ('93000000-0000-0000-0000-000000000001', 'car', 'Carro', 'Marca', 'Modelo', 10000);

select throws_ok(
  $$insert into public.trips(id, vehicle_id, start_odometer, end_odometer, started_at)
    values ('94000000-0000-0000-0000-000000000001', '93000000-0000-0000-0000-000000000001', 10000, 9000, now())$$,
  '23514', null, 'rejects end_odometer lower than start_odometer'
);
select throws_ok(
  $$insert into public.trips(id, vehicle_id, start_odometer, started_at, ended_at)
    values ('94000000-0000-0000-0000-000000000002', '93000000-0000-0000-0000-000000000001', 10000, now(), now())$$,
  '23514', null, 'rejects ended_at without end_odometer'
);
select lives_ok(
  $$insert into public.trips(id, vehicle_id, start_odometer, started_at)
    values ('94000000-0000-0000-0000-000000000003', '93000000-0000-0000-0000-000000000001', 10000, now())$$,
  'accepts an open trip without an end'
);
select lives_ok(
  $$update public.trips set end_odometer = 10200, ended_at = now()
    where id = '94000000-0000-0000-0000-000000000003'$$,
  'completing a trip with a valid odometer succeeds'
);
select is(
  (select current_odometer from public.vehicles where id = '93000000-0000-0000-0000-000000000001'),
  10200, 'completing a trip advances the vehicle odometer'
);

select * from finish();
rollback;
