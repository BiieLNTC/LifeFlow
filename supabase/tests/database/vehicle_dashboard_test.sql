begin;
select plan(7);

select has_view('public', 'vehicle_dashboard', 'vehicle dashboard view exists');

insert into auth.users(id, email)
values ('15000000-0000-0000-0000-000000000001', 'dashboard@motora.test');
select set_config('request.jwt.claim.sub', '15000000-0000-0000-0000-000000000001', true);
set local role authenticated;

insert into public.vehicles(
  id, vehicle_type, nickname, brand, model, current_odometer
) values (
  '25000000-0000-0000-0000-000000000001', 'car', 'i30', 'Hyundai', 'i30', 11000
);

insert into public.refuelings(
  id, vehicle_id, refueling_date, odometer, liters, unit_price,
  total_amount, fuel_type, full_tank
) values
  (
    '35000000-0000-0000-0000-000000000001',
    '25000000-0000-0000-0000-000000000001',
    date_trunc('month', current_date)::date + 1,
    10000, 40, 6.25, 250, 'gasoline', true
  ),
  (
    '35000000-0000-0000-0000-000000000002',
    '25000000-0000-0000-0000-000000000001',
    date_trunc('month', current_date)::date + 10,
    10400, 40, 6.25, 250, 'gasoline', true
  );

insert into public.expenses(
  id, vehicle_id, category, expense_date, amount, description
) values (
  '45000000-0000-0000-0000-000000000001',
  '25000000-0000-0000-0000-000000000001',
  'toll', date_trunc('month', current_date)::date + 5, 50, 'Pedágio'
);

insert into public.reminders(
  id, vehicle_id, description, target_odometer
) values (
  '55000000-0000-0000-0000-000000000001',
  '25000000-0000-0000-0000-000000000001',
  'Troca de óleo', 11500
);

select is(
  (select count(*)::integer from public.vehicle_dashboard),
  1, 'returns one row per active vehicle'
);
select is(
  (select monthly_spending from public.vehicle_dashboard),
  550.00::numeric, 'consolidates monthly spending once'
);
select is(
  (select consumption_km_l from public.vehicle_dashboard),
  10.00::numeric, 'calculates consumption from a complete tank cycle'
);
select is(
  (select cost_per_km from public.vehicle_dashboard),
  1.38::numeric, 'calculates monthly cost per measured kilometer'
);
select is(
  (select next_reminder_description from public.vehicle_dashboard),
  'Troca de óleo', 'returns the next care'
);
select is(
  (select attention_count from public.vehicle_dashboard),
  1, 'counts reminders that need attention'
);

select * from finish();
rollback;
