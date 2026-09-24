begin;
select plan(9);

select has_table('public', 'reminders', 'reminders table exists');
select has_view('public', 'reminder_details', 'reminder details view exists');

insert into auth.users(id, email)
values ('14000000-0000-0000-0000-000000000001', 'reminder@motora.test');
select set_config('request.jwt.claim.sub', '14000000-0000-0000-0000-000000000001', true);
set local role authenticated;
insert into public.vehicles(id, vehicle_type, nickname, brand, model, current_odometer)
values ('24000000-0000-0000-0000-000000000001', 'car', 'Carro', 'Marca', 'Modelo', 10000);

select lives_ok(
  $$insert into public.reminders(id, vehicle_id, description, target_odometer)
    values ('34000000-0000-0000-0000-000000000001', '24000000-0000-0000-0000-000000000001', 'Troca de óleo', 11000)$$,
  'accepts odometer reminder'
);
select lives_ok(
  $$insert into public.reminders(id, vehicle_id, description, target_date)
    values ('34000000-0000-0000-0000-000000000002', '24000000-0000-0000-0000-000000000001', 'Seguro', current_date + 31)$$,
  'accepts date reminder'
);
select throws_ok(
  $$insert into public.reminders(id, vehicle_id, description)
    values ('34000000-0000-0000-0000-000000000003', '24000000-0000-0000-0000-000000000001', 'Sem alvo')$$,
  '23514', null, 'requires at least one target'
);
select is(
  public.reminder_urgency(10000, null, 10000, current_date),
  'overdue', 'current odometer is overdue'
);
select is(
  public.reminder_urgency(11000, null, 10000, current_date),
  'near', 'one thousand kilometers is near'
);
select is(
  public.reminder_urgency(null, current_date + 31, 10000, current_date),
  'upcoming', 'more than thirty days is upcoming'
);
select is(
  (select visual_status from public.reminder_details
   where id = '34000000-0000-0000-0000-000000000001'),
  'near', 'view applies centralized urgency'
);

select * from finish();
rollback;
