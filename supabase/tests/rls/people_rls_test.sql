begin;
select plan(3);

insert into auth.users(id, email) values
  ('72000000-0000-0000-0000-000000000001', 'people-a@lifeflow.test'),
  ('72000000-0000-0000-0000-000000000002', 'people-b@lifeflow.test');

select set_config('request.jwt.claim.sub', '72000000-0000-0000-0000-000000000001', true);
set local role authenticated;
select lives_ok(
  $$insert into public.people(id, name) values ('73000000-0000-0000-0000-000000000001', 'Maria')$$,
  'owner inserts person'
);
select is((select count(*)::integer from public.people), 1, 'owner reads own person');

reset role;
select set_config('request.jwt.claim.sub', '72000000-0000-0000-0000-000000000002', true);
set local role authenticated;
select is((select count(*)::integer from public.people), 0, 'other user cannot read person');

select * from finish();
rollback;
