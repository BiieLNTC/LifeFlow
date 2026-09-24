begin;
select plan(4);

select has_table('public', 'categories', 'categories table exists');

insert into auth.users(id, email)
values ('70000000-0000-0000-0000-000000000001', 'categories@lifeflow.test');
select set_config('request.jwt.claim.sub', '70000000-0000-0000-0000-000000000001', true);
set local role authenticated;

select lives_ok(
  $$insert into public.categories(id, description, purpose)
    values ('71000000-0000-0000-0000-000000000001', 'Mercado', 'expense')$$,
  'accepts valid category'
);
select throws_ok(
  $$insert into public.categories(id, description, purpose)
    values ('71000000-0000-0000-0000-000000000002', 'mercado', 'income')$$,
  '23505', null, 'rejects duplicate description case-insensitively for the same user'
);
select throws_ok(
  $$insert into public.categories(id, description, purpose)
    values ('71000000-0000-0000-0000-000000000003', 'Salário', 'invalid')$$,
  '23514', null, 'rejects invalid purpose'
);

select * from finish();
rollback;
