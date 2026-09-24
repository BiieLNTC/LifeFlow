begin;
select plan(5);
select has_table('public', 'refuelings', 'refuelings table exists');
select col_type_is('public', 'refuelings', 'unit_price', 'numeric(10,4)', 'unit price keeps four decimals');
insert into auth.users (id,email) values ('12000000-0000-0000-0000-000000000001','fuel@motora.test');
select set_config('request.jwt.claim.sub','12000000-0000-0000-0000-000000000001',true);
set local role authenticated;
insert into public.vehicles(id,vehicle_type,nickname,brand,model)
values('22000000-0000-0000-0000-000000000001','car','Carro','Marca','Modelo');
select lives_ok($$insert into public.refuelings(id,vehicle_id,refueling_date,odometer,liters,unit_price,total_amount,fuel_type,full_tank) values('32000000-0000-0000-0000-000000000001','22000000-0000-0000-0000-000000000001','2026-09-01',10000,40,6.25,250,'gasoline',true)$$,'accepts valid refueling');
select throws_ok($$insert into public.refuelings(id,vehicle_id,refueling_date,odometer,liters,unit_price,total_amount,fuel_type) values('32000000-0000-0000-0000-000000000002','22000000-0000-0000-0000-000000000001','2026-09-02',10100,20,6,10,'gasoline')$$,'23514',null,'rejects inconsistent total');
insert into public.refuelings(id,vehicle_id,refueling_date,odometer,liters,unit_price,total_amount,fuel_type,full_tank) values('32000000-0000-0000-0000-000000000003','22000000-0000-0000-0000-000000000001','2026-09-10',10400,40,6.25,250,'gasoline',true);
select is((select consumption_km_l from public.refueling_details where id='32000000-0000-0000-0000-000000000003'),10.00::numeric,'calculates full-tank consumption');
select * from finish(); rollback;
