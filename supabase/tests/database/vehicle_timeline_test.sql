begin;
select plan(6);

select has_view('public', 'vehicle_timeline', 'vehicle timeline view exists');

insert into auth.users(id, email)
values ('16000000-0000-0000-0000-000000000001', 'timeline@motora.test');
select set_config('request.jwt.claim.sub', '16000000-0000-0000-0000-000000000001', true);
set local role authenticated;

insert into public.vehicles(id, vehicle_type, nickname, brand, model)
values (
  '26000000-0000-0000-0000-000000000001',
  'car', 'Carro', 'Marca', 'Modelo'
);

insert into public.refuelings(
  id, vehicle_id, refueling_date, odometer, liters, unit_price,
  total_amount, fuel_type, full_tank
) values (
  '36000000-0000-0000-0000-000000000001',
  '26000000-0000-0000-0000-000000000001',
  '2026-09-19', 10000, 40, 6.25, 250, 'gasoline', true
);

select public.save_maintenance(
  '46000000-0000-0000-0000-000000000001',
  '26000000-0000-0000-0000-000000000001',
  '2026-09-10',
  9800,
  'preventive',
  'Oficina Motora',
  null,
  '[{"id":"56000000-0000-0000-0000-000000000001","category":"oil","description":"Troca de óleo","part_amount":200,"labor_amount":50}]'::jsonb
);

insert into public.expenses(
  id, vehicle_id, category, expense_date, amount, description
) values (
  '66000000-0000-0000-0000-000000000001',
  '26000000-0000-0000-0000-000000000001',
  'toll', '2026-09-05', 20, 'Pedágio'
);

select is(
  (select count(*)::integer from public.vehicle_timeline),
  3, 'consolidates the three event sources'
);
select is(
  (select title from public.vehicle_timeline where event_type = 'maintenance'),
  'Troca de óleo', 'uses maintenance item as title'
);
select is(
  (select amount from public.vehicle_timeline where event_type = 'refueling'),
  250.00::numeric, 'keeps refueling amount'
);
select is(
  (select odometer from public.vehicle_timeline where event_type = 'expense'),
  null::integer, 'expense has no artificial odometer'
);
select is(
  (
    select string_agg(event_type, ',' order by occurred_on desc)
    from public.vehicle_timeline
  ),
  'refueling,maintenance,expense', 'supports chronological ordering'
);

select * from finish();
rollback;
