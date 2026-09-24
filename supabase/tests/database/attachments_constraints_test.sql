begin;
select plan(8);

select has_table('public', 'attachments', 'attachments table exists');
select is(
  (select public from storage.buckets where id = 'vehicle-attachments'),
  false, 'attachment bucket is private'
);
select is(
  (select file_size_limit from storage.buckets where id = 'vehicle-attachments'),
  10485760::bigint, 'bucket limits files to ten megabytes'
);

insert into auth.users(id, email)
values ('17000000-0000-0000-0000-000000000001', 'attachment@motora.test');
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
  'accepts valid attachment metadata'
);
select throws_ok(
  $$insert into public.attachments(
      id, vehicle_id, entity_type, entity_id, file_name,
      content_type, file_size, storage_path
    ) values (
      '47000000-0000-0000-0000-000000000002',
      '27000000-0000-0000-0000-000000000001',
      'maintenance',
      '37000000-0000-0000-0000-000000000001',
      'virus.exe', 'application/octet-stream', 1024,
      'users/17000000-0000-0000-0000-000000000001/vehicles/27000000-0000-0000-0000-000000000001/maintenance/37000000-0000-0000-0000-000000000001/47000000-0000-0000-0000-000000000002.exe'
    )$$,
  '23514', null, 'rejects unsupported content type'
);
select throws_ok(
  $$insert into public.attachments(
      id, vehicle_id, entity_type, entity_id, file_name,
      content_type, file_size, storage_path
    ) values (
      '47000000-0000-0000-0000-000000000003',
      '27000000-0000-0000-0000-000000000001',
      'maintenance',
      '37000000-0000-0000-0000-000000000001',
      'grande.pdf', 'application/pdf', 10485761,
      'users/17000000-0000-0000-0000-000000000001/vehicles/27000000-0000-0000-0000-000000000001/maintenance/37000000-0000-0000-0000-000000000001/47000000-0000-0000-0000-000000000003.pdf'
    )$$,
  '23514', null, 'rejects oversized metadata'
);
select throws_ok(
  $$insert into public.attachments(
      id, vehicle_id, entity_type, entity_id, file_name,
      content_type, file_size, storage_path
    ) values (
      '47000000-0000-0000-0000-000000000004',
      '27000000-0000-0000-0000-000000000001',
      'maintenance',
      '37000000-0000-0000-0000-000000000001',
      'nota.pdf', 'application/pdf', 1024,
      'users/outro/nota.pdf'
    )$$,
  '23514', null, 'rejects path outside the owner hierarchy'
);
select is(
  (select count(*)::integer from public.attachments),
  1, 'only valid metadata was stored'
);

select * from finish();
rollback;
