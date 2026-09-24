alter table public.maintenances
  add constraint maintenances_id_vehicle_unique unique (id, vehicle_id);

create table public.reminders (
  id uuid primary key,
  vehicle_id uuid not null references public.vehicles (id) on delete cascade,
  description text not null,
  target_odometer integer,
  target_date date,
  status text not null default 'active',
  origin_maintenance_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  last_synced_at timestamptz,

  constraint reminders_description_check
    check (char_length(btrim(description)) between 1 and 160),
  constraint reminders_target_odometer_check
    check (target_odometer is null or target_odometer >= 0),
  constraint reminders_target_check
    check (target_odometer is not null or target_date is not null),
  constraint reminders_status_check
    check (status in ('active', 'completed')),
  constraint reminders_origin_maintenance_fk
    foreign key (origin_maintenance_id, vehicle_id)
    references public.maintenances (id, vehicle_id)
);

create index reminders_vehicle_status_target_idx
  on public.reminders (vehicle_id, status, target_date, target_odometer)
  where deleted_at is null;

create trigger reminders_set_updated_at
before update on public.reminders
for each row execute function public.set_updated_at();

create function public.reminder_urgency(
  p_target_odometer integer,
  p_target_date date,
  p_current_odometer integer,
  p_reference_date date
)
returns text
language sql
stable
set search_path = ''
as $$
  select case
    when p_target_odometer is not null
         and p_target_odometer <= p_current_odometer then 'overdue'
    when p_target_date is not null
         and p_target_date <= p_reference_date then 'overdue'
    when p_target_odometer is not null
         and p_target_odometer - p_current_odometer <= 1000 then 'near'
    when p_target_date is not null
         and p_target_date - p_reference_date <= 30 then 'near'
    else 'upcoming'
  end;
$$;

revoke all on function public.reminder_urgency(integer, date, integer, date)
  from public, anon;
grant execute on function public.reminder_urgency(integer, date, integer, date)
  to authenticated;

alter table public.reminders enable row level security;
alter table public.reminders force row level security;
revoke all on table public.reminders from anon, authenticated;
grant select, insert, update on table public.reminders to authenticated;

create policy "reminders_select_own" on public.reminders
for select to authenticated using (
  exists (
    select 1 from public.vehicles
    where vehicles.id = reminders.vehicle_id
      and vehicles.user_id = (select auth.uid())
  )
);

create policy "reminders_insert_own" on public.reminders
for insert to authenticated with check (
  exists (
    select 1 from public.vehicles
    where vehicles.id = reminders.vehicle_id
      and vehicles.user_id = (select auth.uid())
      and vehicles.deleted_at is null
  )
);

create policy "reminders_update_own" on public.reminders
for update to authenticated
using (
  exists (
    select 1 from public.vehicles
    where vehicles.id = reminders.vehicle_id
      and vehicles.user_id = (select auth.uid())
  )
)
with check (
  exists (
    select 1 from public.vehicles
    where vehicles.id = reminders.vehicle_id
      and vehicles.user_id = (select auth.uid())
  )
);

create view public.reminder_details
with (security_invoker = true)
as
select
  reminders.*,
  vehicles.current_odometer,
  case
    when reminders.status = 'completed' then 'completed'
    else public.reminder_urgency(
      reminders.target_odometer,
      reminders.target_date,
      vehicles.current_odometer,
      current_date
    )
  end as visual_status,
  reminders.target_odometer - vehicles.current_odometer as remaining_km,
  reminders.target_date - current_date as remaining_days
from public.reminders
join public.vehicles on vehicles.id = reminders.vehicle_id
where reminders.deleted_at is null;

revoke all on public.reminder_details from anon, authenticated;
grant select on public.reminder_details to authenticated;

comment on table public.reminders is 'Lembretes por quilometragem, data ou ambos.';
comment on function public.reminder_urgency(integer, date, integer, date)
  is 'Centraliza proximidade: near em ate 1000 km ou 30 dias.';
comment on view public.reminder_details
  is 'Lembretes com urgencia e distancias calculadas pelo banco.';
