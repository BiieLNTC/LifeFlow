begin;

select plan(9);

insert into auth.users (id, email)
values ('17000000-0000-0000-0000-000000000001', 'odometer@motora.test');

select set_config(
  'request.jwt.claim.sub',
  '17000000-0000-0000-0000-000000000001',
  true
);
set local role authenticated;

insert into public.vehicles (id, vehicle_type, nickname, brand, model)
values (
  '27000000-0000-0000-0000-000000000001',
  'car', 'Carro', 'Marca', 'Modelo'
);

insert into public.refuelings (
  id, vehicle_id, refueling_date, odometer, liters,
  unit_price, total_amount, fuel_type
) values (
  '37000000-0000-0000-0000-000000000001',
  '27000000-0000-0000-0000-000000000001',
  current_date - 2, 10000, 10, 5, 50, 'gasoline'
);

select is(
  (select current_odometer from public.vehicles
    where id = '27000000-0000-0000-0000-000000000001'),
  10000,
  'refueling advances the current odometer'
);

select lives_ok(
  $$
    select public.save_maintenance(
      '47000000-0000-0000-0000-000000000001',
      '27000000-0000-0000-0000-000000000001',
      current_date - 1, 10200, 'preventive', null, null,
      '[{"id":"57000000-0000-0000-0000-000000000001","category":"oil","description":"Oleo","part_amount":100,"labor_amount":20}]'::jsonb
    )
  $$,
  'maintenance with consistent date and odometer is accepted'
);

select is(
  (select current_odometer from public.vehicles
    where id = '27000000-0000-0000-0000-000000000001'),
  10200,
  'maintenance advances the current odometer'
);

select lives_ok(
  $$
    insert into public.refuelings (
      id, vehicle_id, refueling_date, odometer, liters,
      unit_price, total_amount, fuel_type
    ) values (
      '37000000-0000-0000-0000-000000000002',
      '27000000-0000-0000-0000-000000000001',
      current_date - 3, 9900, 10, 5, 50, 'gasoline'
    )
  $$,
  'historical event with lower odometer remains valid'
);

select is(
  (select current_odometer from public.vehicles
    where id = '27000000-0000-0000-0000-000000000001'),
  10200,
  'historical event never lowers the current odometer'
);

select throws_ok(
  $$
    insert into public.refuelings (
      id, vehicle_id, refueling_date, odometer, liters,
      unit_price, total_amount, fuel_type
    ) values (
      '37000000-0000-0000-0000-000000000003',
      '27000000-0000-0000-0000-000000000001',
      current_date - 3, 10300, 10, 5, 50, 'gasoline'
    )
  $$,
  '23514', null,
  'rejects odometer higher than a later event'
);

select throws_ok(
  $$
    insert into public.refuelings (
      id, vehicle_id, refueling_date, odometer, liters,
      unit_price, total_amount, fuel_type
    ) values (
      '37000000-0000-0000-0000-000000000004',
      '27000000-0000-0000-0000-000000000001',
      current_date, 10100, 10, 5, 50, 'gasoline'
    )
  $$,
  '23514', null,
  'rejects odometer lower than an earlier event'
);

select throws_ok(
  $$
    insert into public.expenses (
      id, vehicle_id, category, expense_date, amount, description
    ) values (
      '67000000-0000-0000-0000-000000000001',
      '27000000-0000-0000-0000-000000000001',
      'other', current_date + 1, 10, 'Futura'
    )
  $$,
  '23514', null,
  'rejects a future expense date'
);

select throws_ok(
  $$
    update public.vehicles
    set purchase_date = current_date + 1
    where id = '27000000-0000-0000-0000-000000000001'
  $$,
  '23514', null,
  'rejects a future purchase date'
);

select * from finish();
rollback;
