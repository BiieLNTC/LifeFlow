begin;
select plan(4);

select has_table('public', 'savings_goals', 'savings_goals table exists');
select has_table('public', 'goal_contributions', 'goal_contributions table exists');

insert into auth.users(id, email)
values ('86000000-0000-0000-0000-000000000001', 'goals@lifeflow.test');
select set_config('request.jwt.claim.sub', '86000000-0000-0000-0000-000000000001', true);
set local role authenticated;

select lives_ok(
  $$insert into public.savings_goals(id, title, target_amount)
    values ('87000000-0000-0000-0000-000000000001', 'Viagem', 5000)$$,
  'accepts valid savings goal'
);

select throws_ok(
  $$insert into public.goal_contributions(id, goal_id, amount, contribution_date)
    values ('88000000-0000-0000-0000-000000000001', '87000000-0000-0000-0000-000000000001', 100, current_date + 1)$$,
  '23514', null, 'rejects contribution dated in the future'
);

select * from finish();
rollback;
