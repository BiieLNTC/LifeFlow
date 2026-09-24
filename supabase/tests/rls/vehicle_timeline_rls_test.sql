begin;
select plan(2);

insert into auth.users(id, email) values
  ('16000000-0000-0000-0000-000000000001', 'timeline-a@motora.test'),
  ('16000000-0000-0000-0000-000000000002', 'timeline-b@motora.test');

select set_config('request.jwt.claim.sub', '16000000-0000-0000-0000-000000000001', true);
set local role authenticated;
insert into public.vehicles(id, vehicle_type, nickname, brand, model)
values (
  '26000000-0000-0000-0000-000000000001',
  'car', 'Carro', 'Marca', 'Modelo'
);
insert into public.expenses(
  id, vehicle_id, category, expense_date, amount, description
) values (
  '66000000-0000-0000-0000-000000000001',
  '26000000-0000-0000-0000-000000000001',
  'other', '2026-09-20', 20, 'Despesa'
);
select is(
  (select count(*)::integer from public.vehicle_timeline),
  1, 'owner reads own timeline'
);

reset role;
select set_config('request.jwt.claim.sub', '16000000-0000-0000-0000-000000000002', true);
set local role authenticated;
select is(
  (select count(*)::integer from public.vehicle_timeline),
  0, 'other user cannot read timeline'
);

select * from finish();
rollback;
