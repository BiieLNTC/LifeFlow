begin;
select plan(6);

insert into auth.users(id, email) values
  ('17000000-0000-0000-0000-000000000001', 'attachment-a@motora.test'),
  ('17000000-0000-0000-0000-000000000002', 'attachment-b@motora.test');

select set_config('request.jwt.claim.sub', '17000000-0000-0000-0000-000000000001', true);
set local role authenticated;
insert into public.vehicles(id, vehicle_type, nickname, brand, model)
values (
  '27000000-0000-0000-0000-000000000001',
  'car', 'Carro', 'Marca', 'Modelo'
);
insert into public.maintenances(
  id, vehicle_id, maintenance_date, odometer, maintenance_type
) values (
  '37000000-0000-0000-0000-000000000001',
  '27000000-0000-0000-0000-000000000001',
  '2026-09-21', 10000, 'preventive'
);

select lives_ok(
  $$insert into public.attachments(
      id, vehicle_id, entity_type, entity_id, file_name,
      content_type, file_size, storage_path
    ) values (
      '47000000-0000-0000-0000-000000000001',
      '27000000-0000-0000-0000-000000000001',
      'maintenance',
      '37000000-0000-0000-0000-000000000001',
      'nota.pdf', 'application/pdf', 1024,
      'users/17000000-0000-0000-0000-000000000001/vehicles/27000000-0000-0000-0000-000000000001/maintenance/37000000-0000-0000-0000-000000000001/47000000-0000-0000-0000-000000000001.pdf'
    )$$,
  'owner inserts attachment metadata'
);
select lives_ok(
  $$insert into storage.objects(id, bucket_id, name, owner, owner_id)
    values (
      '57000000-0000-0000-0000-000000000001',
      'vehicle-attachments',
      'users/17000000-0000-0000-0000-000000000001/vehicles/27000000-0000-0000-0000-000000000001/maintenance/37000000-0000-0000-0000-000000000001/47000000-0000-0000-0000-000000000001.pdf',
      '17000000-0000-0000-0000-000000000001',
      '17000000-0000-0000-0000-000000000001'
    )$$,
  'owner inserts storage object'
);
select is(
  (select count(*)::integer from storage.objects where bucket_id = 'vehicle-attachments'),
  1, 'owner reads storage object'
);

reset role;
select set_config('request.jwt.claim.sub', '17000000-0000-0000-0000-000000000002', true);
set local role authenticated;
select is(
  (select count(*)::integer from public.attachments),
  0, 'other user cannot read attachment metadata'
);
select is(
  (select count(*)::integer from storage.objects where bucket_id = 'vehicle-attachments'),
  0, 'other user cannot read storage object'
);
select throws_ok(
  $$insert into storage.objects(id, bucket_id, name, owner, owner_id)
    values (
      '57000000-0000-0000-0000-000000000002',
      'vehicle-attachments',
      'users/17000000-0000-0000-0000-000000000001/vehicles/27000000-0000-0000-0000-000000000001/maintenance/37000000-0000-0000-0000-000000000001/47000000-0000-0000-0000-000000000002.pdf',
      '17000000-0000-0000-0000-000000000002',
      '17000000-0000-0000-0000-000000000002'
    )$$,
  '42501', null, 'other user cannot write into owner path'
);

select * from finish();
rollback;
