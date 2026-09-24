begin;

select plan(6);

select has_table('public', 'vehicles', 'vehicles table exists');
select col_type_is('public', 'vehicles', 'purchase_price', 'numeric(14,2)', 'purchase price uses explicit numeric precision');
select has_check('public', 'vehicles', 'vehicles table has check constraints');

insert into auth.users (id, email)
values ('10000000-0000-0000-0000-000000000001', 'owner@motora.test');

select set_config('request.jwt.claim.sub', '10000000-0000-0000-0000-000000000001', true);
set local role authenticated;

select lives_ok(
  $$
    insert into public.vehicles (
      id, vehicle_type, nickname, brand, model, manufacture_year, model_year, current_odometer
    ) values (
      '20000000-0000-0000-0000-000000000001', 'car', 'Meu carro', 'Hyundai', 'i30', 2010, 2011, 127340
    )
  $$,
  'accepts a valid vehicle'
);

select throws_ok(
  $$
    insert into public.vehicles (
      id, vehicle_type, nickname, brand, model, current_odometer
    ) values (
      '20000000-0000-0000-0000-000000000002', 'car', 'Inválido', 'Marca', 'Modelo', -1
    )
  $$,
  '23514',
  null,
  'rejects a negative odometer'
);

select throws_ok(
  $$
    insert into public.vehicles (
      id, vehicle_type, nickname, brand, model, license_plate
    ) values (
      '20000000-0000-0000-0000-000000000003', 'car', 'Placa inválida', 'Marca', 'Modelo', 'INVALIDA'
    )
  $$,
  '23514',
  null,
  'rejects an invalid Brazilian plate'
);

select * from finish();
rollback;
