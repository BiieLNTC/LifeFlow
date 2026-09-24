begin;
select plan(2);

insert into auth.users(id, email) values
  ('15000000-0000-0000-0000-000000000001', 'dashboard-a@motora.test'),
  ('15000000-0000-0000-0000-000000000002', 'dashboard-b@motora.test');

select set_config('request.jwt.claim.sub', '15000000-0000-0000-0000-000000000001', true);
set local role authenticated;
insert into public.vehicles(id, vehicle_type, nickname, brand, model)
values (
  '25000000-0000-0000-0000-000000000001',
  'car', 'A', 'Marca', 'Modelo'
);
select is(
  (select count(*)::integer from public.vehicle_dashboard),
  1, 'owner reads own dashboard'
);

reset role;
select set_config('request.jwt.claim.sub', '15000000-0000-0000-0000-000000000002', true);
set local role authenticated;
select is(
  (select count(*)::integer from public.vehicle_dashboard),
  0, 'other user cannot read dashboard'
);

select * from finish();
rollback;
