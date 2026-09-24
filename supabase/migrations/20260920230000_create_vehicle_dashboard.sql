create view public.vehicle_dashboard
with (security_invoker = true)
as
with monthly_financial as (
  select
    vehicle_id,
    sum(amount) as monthly_spending
  from public.financial_entries
  where entry_date >= date_trunc('month', current_date)::date
    and entry_date < (date_trunc('month', current_date) + interval '1 month')::date
  group by vehicle_id
),
monthly_distance as (
  select
    vehicle_id,
    case
      when count(distinct odometer) >= 2 then max(odometer) - min(odometer)
      else null
    end as distance_km
  from public.refuelings
  where deleted_at is null
    and refueling_date >= date_trunc('month', current_date)::date
    and refueling_date < (date_trunc('month', current_date) + interval '1 month')::date
  group by vehicle_id
),
full_tanks as (
  select
    id,
    vehicle_id,
    refueling_date,
    odometer,
    lag(odometer) over (
      partition by vehicle_id
      order by odometer, refueling_date, created_at
    ) as previous_odometer
  from public.refuelings
  where full_tank and deleted_at is null
),
completed_cycles as (
  select
    full_tanks.vehicle_id,
    full_tanks.refueling_date,
    full_tanks.odometer - full_tanks.previous_odometer as distance_km,
    (
      select sum(refuelings.liters)
      from public.refuelings
      where refuelings.vehicle_id = full_tanks.vehicle_id
        and refuelings.deleted_at is null
        and refuelings.odometer > full_tanks.previous_odometer
        and refuelings.odometer <= full_tanks.odometer
    ) as consumed_liters
  from full_tanks
  where full_tanks.previous_odometer is not null
    and full_tanks.odometer > full_tanks.previous_odometer
),
monthly_consumption as (
  select
    vehicle_id,
    round(sum(distance_km)::numeric / nullif(sum(consumed_liters), 0), 2)
      as consumption_km_l
  from completed_cycles
  where refueling_date >= date_trunc('month', current_date)::date
    and refueling_date < (date_trunc('month', current_date) + interval '1 month')::date
  group by vehicle_id
),
ranked_reminders as (
  select
    reminder_details.*,
    row_number() over (
      partition by vehicle_id
      order by
        case visual_status
          when 'overdue' then 0
          when 'near' then 1
          else 2
        end,
        least(
          coalesce(remaining_km / 1000.0, 2147483647),
          coalesce(remaining_days / 30.0, 2147483647)
        ),
        created_at
    ) as position
  from public.reminder_details
  where status = 'active'
),
reminder_counts as (
  select
    vehicle_id,
    count(*) filter (where visual_status in ('near', 'overdue')) as attention_count
  from public.reminder_details
  where status = 'active'
  group by vehicle_id
)
select
  vehicles.id as vehicle_id,
  vehicles.vehicle_type,
  vehicles.nickname,
  vehicles.brand,
  vehicles.model,
  vehicles.version,
  vehicles.manufacture_year,
  vehicles.model_year,
  vehicles.current_odometer,
  vehicles.photo_path,
  coalesce(monthly_financial.monthly_spending, 0)::numeric(14, 2)
    as monthly_spending,
  monthly_consumption.consumption_km_l,
  case
    when monthly_distance.distance_km > 0 then
      round(
        coalesce(monthly_financial.monthly_spending, 0)
          / monthly_distance.distance_km,
        2
      )
    else null
  end as cost_per_km,
  monthly_distance.distance_km as monthly_distance_km,
  coalesce(reminder_counts.attention_count, 0)::integer as attention_count,
  ranked_reminders.id as next_reminder_id,
  ranked_reminders.description as next_reminder_description,
  ranked_reminders.target_odometer as next_reminder_odometer,
  ranked_reminders.target_date as next_reminder_date,
  ranked_reminders.visual_status as next_reminder_status,
  ranked_reminders.remaining_km as next_reminder_remaining_km,
  ranked_reminders.remaining_days as next_reminder_remaining_days
from public.vehicles
left join monthly_financial
  on monthly_financial.vehicle_id = vehicles.id
left join monthly_distance
  on monthly_distance.vehicle_id = vehicles.id
left join monthly_consumption
  on monthly_consumption.vehicle_id = vehicles.id
left join reminder_counts
  on reminder_counts.vehicle_id = vehicles.id
left join ranked_reminders
  on ranked_reminders.vehicle_id = vehicles.id
  and ranked_reminders.position = 1
where vehicles.deleted_at is null
  and vehicles.active;

revoke all on public.vehicle_dashboard from anon, authenticated;
grant select on public.vehicle_dashboard to authenticated;

comment on view public.vehicle_dashboard is
  'Resumo da Home por veiculo com gastos, consumo, custo por km e proximo cuidado.';
