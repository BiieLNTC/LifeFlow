create view public.vehicle_timeline
with (security_invoker = true)
as
with maintenance_summaries as (
  select
    maintenance_id,
    min(description) as first_description,
    count(*)::integer as item_count
  from public.maintenance_items
  group by maintenance_id
)
select
  refuelings.id as event_id,
  refuelings.vehicle_id,
  'refueling'::text as event_type,
  refuelings.refueling_date as occurred_on,
  'Abastecimento'::text as title,
  refuelings.gas_station as secondary_text,
  refuelings.fuel_type as category,
  refuelings.odometer,
  refuelings.total_amount as amount,
  refuelings.created_at
from public.refuelings
where refuelings.deleted_at is null

union all

select
  maintenances.id,
  maintenances.vehicle_id,
  'maintenance'::text,
  maintenances.maintenance_date,
  case
    when maintenance_summaries.item_count is null then 'Manutenção'
    when maintenance_summaries.item_count = 1 then maintenance_summaries.first_description
    when maintenance_summaries.item_count = 2 then
      maintenance_summaries.first_description || ' + 1 item'
    else
      maintenance_summaries.first_description || ' + '
        || (maintenance_summaries.item_count - 1)::text || ' itens'
  end,
  maintenances.workshop,
  maintenances.maintenance_type,
  maintenances.odometer,
  maintenances.total_amount,
  maintenances.created_at
from public.maintenances
left join maintenance_summaries
  on maintenance_summaries.maintenance_id = maintenances.id
where maintenances.deleted_at is null

union all

select
  expenses.id,
  expenses.vehicle_id,
  'expense'::text,
  expenses.expense_date,
  expenses.description,
  expenses.notes,
  expenses.category,
  null::integer,
  expenses.amount,
  expenses.created_at
from public.expenses
where expenses.deleted_at is null;

revoke all on public.vehicle_timeline from anon, authenticated;
grant select on public.vehicle_timeline to authenticated;

comment on view public.vehicle_timeline is
  'Timeline unificada de abastecimentos, manutencoes e despesas, protegida pelas RLS de origem.';
