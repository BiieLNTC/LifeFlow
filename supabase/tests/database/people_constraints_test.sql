begin;
select plan(3);

select has_table('public', 'people', 'people table exists');

insert into auth.users(id, email)
values ('72000000-0000-0000-0000-000000000001', 'people@lifeflow.test');
select set_config('request.jwt.claim.sub', '72000000-0000-0000-0000-000000000001', true);
set local role authenticated;

select lives_ok(
  $$insert into public.people(id, name, birth_date)
    values ('73000000-0000-0000-0000-000000000001', 'Maria', '1990-05-10')$$,
  'accepts valid person'
);
select throws_ok(
  $$insert into public.people(id, name, birth_date)
    values ('73000000-0000-0000-0000-000000000002', 'Futuro', current_date + 1)$$,
  '23514', null, 'rejects birth date in the future'
);

select * from finish();
rollback;
