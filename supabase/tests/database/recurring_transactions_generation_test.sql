begin;
select plan(4);

insert into auth.users(id, email)
values ('83000000-0000-0000-0000-000000000001', 'recurring-gen@lifeflow.test');
select set_config('request.jwt.claim.sub', '83000000-0000-0000-0000-000000000001', true);
set local role authenticated;
insert into public.categories(id, description, purpose)
values ('84000000-0000-0000-0000-000000000001', 'Assinaturas', 'expense');
insert into public.recurring_transactions(
  id, category_id, description, type, amount, day_of_month, start_date
) values (
  '85000000-0000-0000-0000-000000000001', '84000000-0000-0000-0000-000000000001',
  'Streaming', 'expense', 39.90, 1,
  (date_trunc('month', current_date) - interval '2 months')::date
);

select is(
  (select public.generate_due_recurring_transactions()),
  3, 'generates one occurrence per elapsed month including the current one'
);
select is(
  (select count(*)::integer from public.transactions where source_type = 'recurring'),
  3, 'occurrences are persisted as transactions'
);
select is(
  (select public.generate_due_recurring_transactions()),
  0, 'does not duplicate already generated occurrences'
);
select is(
  (select count(*)::integer from public.transactions where source_type = 'recurring'),
  3, 'transaction count remains stable after re-running generation'
);

select * from finish();
rollback;
