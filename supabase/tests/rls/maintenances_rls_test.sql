begin;

select plan(6);

insert into auth.users (id, email)
values
  ('11000000-0000-0000-0000-000000000001', 'maintenance-a@motora.test'),
  ('11000000-0000-0000-0000-000000000002', 'maintenance-b@motora.test');

select set_config('request.jwt.claim.sub', '11000000-0000-0000-0000-000000000001', true);
set local role authenticated;

insert into public.vehicles (id, vehicle_type, nickname, brand, model)
values ('21000000-0000-0000-0000-000000000001', 'car', 'Carro A', 'Marca', 'Modelo');

select lives_ok(
  $$
    select public.save_maintenance(
      '31000000-0000-0000-0000-000000000001',
      '21000000-0000-0000-0000-000000000001',
      '2026-09-20', 10000, 'corrective', null, null,
      '[{"id":"41000000-0000-0000-0000-000000000001","category":"brakes","description":"Freios","part_amount":100,"labor_amount":50}]'::jsonb
    )
  $$,
  'owner can create a maintenance'
);

select is((select count(*)::integer from public.maintenances), 1, 'owner reads own maintenance');
select is((select count(*)::integer from public.maintenance_items), 1, 'owner reads own items');

reset role;
select set_config('request.jwt.claim.sub', '11000000-0000-0000-0000-000000000002', true);
set local role authenticated;

select is((select count(*)::integer from public.maintenances), 0, 'another user cannot read maintenance');
select is((select count(*)::integer from public.maintenance_items), 0, 'another user cannot read items');

select throws_ok(
  $$
    select public.save_maintenance(
      '31000000-0000-0000-0000-000000000002',
      '21000000-0000-0000-0000-000000000001',
      '2026-09-20', 10000, 'corrective', null, null,
      '[{"id":"41000000-0000-0000-0000-000000000002","category":"brakes","description":"Invasão","part_amount":1,"labor_amount":1}]'::jsonb
    )
  $$,
  '42501', null,
  'another user cannot create maintenance for the vehicle'
);

select * from finish();
rollback;
