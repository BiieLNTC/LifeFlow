begin;
select plan(8);

insert into auth.users(id, email)
values ('99000000-0000-0000-0000-000000000001', 'sync@lifeflow.test');
select set_config('request.jwt.claim.sub', '99000000-0000-0000-0000-000000000001', true);
set local role authenticated;
insert into public.vehicles(id, vehicle_type, nickname, brand, model)
values ('a0000000-0000-0000-0000-000000000001', 'car', 'Carro', 'Marca', 'Modelo');

select is(
  (select count(*)::integer from public.categories where description = 'Veículo'),
  0, 'no vehicle category exists before any vehicle event'
);

-- total_amount is forced to 0 by maintenances_protect_total until items exist,
-- so the sync trigger must not mirror it yet (would violate transactions_amount_check).
insert into public.maintenances(id, vehicle_id, maintenance_date, odometer, maintenance_type, total_amount)
values ('a1000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', current_date, 1000, 'preventive', 350);

select is(
  (select count(*)::integer from public.transactions where source_type = 'maintenance'),
  0, 'does not mirror a maintenance that still has zero total'
);

insert into public.maintenance_items(id, maintenance_id, category, description, part_amount, labor_amount)
values ('a2000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', 'oil', 'Óleo', 400, 100);

select is(
  (select count(*)::integer from public.categories where description = 'Veículo'),
  1, 'lazily creates the Veículo category once the maintenance has a positive total'
);
select is(
  (select amount from public.transactions
   where source_type = 'maintenance' and source_id = 'a1000000-0000-0000-0000-000000000001'),
  500.00::numeric, 'mirrors the maintenance total (computed from items) as a transaction'
);

update public.transactions set amount = 1 where source_type = 'maintenance';
select is(
  (select amount from public.transactions
   where source_type = 'maintenance' and source_id = 'a1000000-0000-0000-0000-000000000001'),
  500.00::numeric, 'client cannot edit an auto-generated transaction directly'
);

delete from public.transactions
where source_type = 'maintenance' and source_id = 'a1000000-0000-0000-0000-000000000001';
select is(
  (select count(*)::integer from public.transactions
   where source_type = 'maintenance' and source_id = 'a1000000-0000-0000-0000-000000000001'),
  1, 'client cannot delete an auto-generated transaction directly'
);

update public.maintenances set deleted_at = now() where id = 'a1000000-0000-0000-0000-000000000001';
select is(
  (select count(*)::integer from public.transactions
   where source_type = 'maintenance' and source_id = 'a1000000-0000-0000-0000-000000000001'),
  0, 'soft-deleting the maintenance removes the mirrored transaction'
);

select throws_ok(
  $$select public.get_or_create_vehicle_category('99000000-0000-0000-0000-000000000001')$$,
  '42501', null, 'authenticated cannot call the SECURITY DEFINER helper directly'
);

select * from finish();
rollback;
