begin;
select plan(4);

insert into auth.users(id, email) values
  ('70000000-0000-0000-0000-000000000001', 'categories-a@lifeflow.test'),
  ('70000000-0000-0000-0000-000000000002', 'categories-b@lifeflow.test');

select set_config('request.jwt.claim.sub', '70000000-0000-0000-0000-000000000001', true);
set local role authenticated;
select lives_ok(
  $$insert into public.categories(id, description, purpose)
    values ('71000000-0000-0000-0000-000000000001', 'Mercado', 'expense')$$,
  'owner inserts category'
);
select is((select count(*)::integer from public.categories), 1, 'owner reads own category');

reset role;
select set_config('request.jwt.claim.sub', '70000000-0000-0000-0000-000000000002', true);
set local role authenticated;
select is((select count(*)::integer from public.categories), 0, 'other user cannot read category');
update public.categories set description = 'Hack' where id = '71000000-0000-0000-0000-000000000001';

reset role;
select set_config('request.jwt.claim.sub', '70000000-0000-0000-0000-000000000001', true);
set local role authenticated;
select is(
  (select description from public.categories where id = '71000000-0000-0000-0000-000000000001'),
  'Mercado', 'other user cannot update category owned by someone else'
);

select * from finish();
rollback;
