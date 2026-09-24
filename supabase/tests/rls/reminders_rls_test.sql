begin;
select plan(4);

insert into auth.users(id, email) values
  ('14000000-0000-0000-0000-000000000001', 'reminder-a@motora.test'),
  ('14000000-0000-0000-0000-000000000002', 'reminder-b@motora.test');

select set_config('request.jwt.claim.sub', '14000000-0000-0000-0000-000000000001', true);
set local role authenticated;
insert into public.vehicles(id, vehicle_type, nickname, brand, model)
values ('24000000-0000-0000-0000-000000000001', 'car', 'A', 'Marca', 'Modelo');
select lives_ok(
  $$insert into public.reminders(id, vehicle_id, description, target_odometer)
    values ('34000000-0000-0000-0000-000000000001', '24000000-0000-0000-0000-000000000001', 'Óleo', 10000)$$,
  'owner inserts reminder'
);
select is(
  (select count(*)::integer from public.reminder_details),
  1, 'owner reads reminder view'
);

reset role;
select set_config('request.jwt.claim.sub', '14000000-0000-0000-0000-000000000002', true);
set local role authenticated;
select is(
  (select count(*)::integer from public.reminders),
  0, 'other user cannot read reminder'
);
select is(
  (select count(*)::integer from public.reminder_details),
  0, 'other user cannot read reminder view'
);

select * from finish();
rollback;
