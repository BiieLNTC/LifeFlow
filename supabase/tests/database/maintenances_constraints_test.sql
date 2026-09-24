begin;

select plan(9);

select has_table('public', 'maintenances', 'maintenances table exists');
select has_table('public', 'maintenance_items', 'maintenance items table exists');
select col_type_is(
  'public', 'maintenances', 'total_amount', 'numeric(14,2)',
  'total uses explicit numeric precision'
);

insert into auth.users (id, email)
values ('11000000-0000-0000-0000-000000000001', 'maintenance@motora.test');

select set_config('request.jwt.claim.sub', '11000000-0000-0000-0000-000000000001', true);
set local role authenticated;

insert into public.vehicles (id, vehicle_type, nickname, brand, model)
values ('21000000-0000-0000-0000-000000000001', 'car', 'i30', 'Hyundai', 'i30');

select lives_ok(
  $$
    select public.save_maintenance(
      '31000000-0000-0000-0000-000000000001',
      '21000000-0000-0000-0000-000000000001',
      '2026-09-20', 127340, 'preventive', 'Oficina Motora', null,
      '[{"id":"41000000-0000-0000-0000-000000000001","category":"oil","description":"Troca de óleo","part_amount":220,"labor_amount":70,"next_replacement_odometer":137340}]'::jsonb
    )
  $$,
  'saves a valid maintenance atomically'
);

select is(
  (select total_amount from public.maintenances where id = '31000000-0000-0000-0000-000000000001'),
  290.00::numeric,
  'calculates total from items'
);

select is(
  (select count(*)::integer from public.maintenance_items where maintenance_id = '31000000-0000-0000-0000-000000000001'),
  1,
  'persists maintenance items'
);

update public.maintenances
set total_amount = 999
where id = '31000000-0000-0000-0000-000000000001';

select is(
  (select total_amount from public.maintenances where id = '31000000-0000-0000-0000-000000000001'),
  290.00::numeric,
  'protects calculated total from direct changes'
);

select throws_ok(
  $$
    select public.save_maintenance(
      '31000000-0000-0000-0000-000000000002',
      '21000000-0000-0000-0000-000000000001',
      '2026-09-20', 127340, 'preventive', null, null, '[]'::jsonb
    )
  $$,
  '23514', null,
  'rejects maintenance without items'
);

select throws_ok(
  $$
    select public.save_maintenance(
      '31000000-0000-0000-0000-000000000003',
      '21000000-0000-0000-0000-000000000001',
      '2026-09-20', 127340, 'preventive', null, null,
      '[{"id":"41000000-0000-0000-0000-000000000003","category":"oil","description":"Óleo","part_amount":1,"labor_amount":0,"next_replacement_odometer":120000}]'::jsonb
    )
  $$,
  '23514', null,
  'rejects an invalid next replacement odometer'
);

select * from finish();
rollback;
