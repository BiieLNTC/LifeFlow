begin;
select plan(4);

insert into auth.users(id, email) values
  ('86000000-0000-0000-0000-000000000001', 'goals-a@lifeflow.test'),
  ('86000000-0000-0000-0000-000000000002', 'goals-b@lifeflow.test');

select set_config('request.jwt.claim.sub', '86000000-0000-0000-0000-000000000001', true);
set local role authenticated;
select lives_ok(
  $$insert into public.savings_goals(id, title, target_amount)
    values ('87000000-0000-0000-0000-000000000001', 'Viagem', 5000)$$,
  'owner inserts savings goal'
);
select lives_ok(
  $$insert into public.goal_contributions(id, goal_id, amount, contribution_date)
    values ('88000000-0000-0000-0000-000000000001', '87000000-0000-0000-0000-000000000001', 500, current_date)$$,
  'owner inserts contribution to own goal'
);

reset role;
select set_config('request.jwt.claim.sub', '86000000-0000-0000-0000-000000000002', true);
set local role authenticated;
select is((select count(*)::integer from public.savings_goals), 0, 'other user cannot read savings goal');
select is((select count(*)::integer from public.goal_contributions), 0, 'other user cannot read contribution');

select * from finish();
rollback;
