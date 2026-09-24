begin;
select plan(5);

select has_view('public', 'notification_items', 'notification_items view exists');

insert into auth.users(id, email)
values ('a3000000-0000-0000-0000-000000000001', 'notify@lifeflow.test');
select set_config('request.jwt.claim.sub', 'a3000000-0000-0000-0000-000000000001', true);
set local role authenticated;
insert into public.vehicles(id, vehicle_type, nickname, brand, model, current_odometer)
values ('a4000000-0000-0000-0000-000000000001', 'car', 'Carro', 'Marca', 'Modelo', 10000);
insert into public.vehicle_documents(id, vehicle_id, type, description, expiry_date)
values ('a5000000-0000-0000-0000-000000000001', 'a4000000-0000-0000-0000-000000000001', 'licensing', 'Licenciamento', current_date + 10);
insert into public.reminders(id, vehicle_id, description, target_odometer)
values ('a6000000-0000-0000-0000-000000000001', 'a4000000-0000-0000-0000-000000000001', 'Troca de óleo', 10000);

select is(
  (select count(*)::integer from public.notification_items where target_type = 'vehicle_document'),
  1, 'lists vehicle documents expiring soon'
);
select is(
  (select count(*)::integer from public.notification_items where target_type = 'reminder'),
  1, 'lists overdue reminders'
);

select is(
  (select vehicle_id from public.notification_items where target_type = 'reminder'),
  'a4000000-0000-0000-0000-000000000001'::uuid, 'reminder carries its vehicle_id'
);
select is(
  (select vehicle_id from public.notification_items where target_type = 'vehicle_document'),
  'a4000000-0000-0000-0000-000000000001'::uuid, 'document carries its vehicle_id'
);

select * from finish();
rollback;
