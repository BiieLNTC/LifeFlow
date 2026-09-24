create table public.trips (
  id uuid primary key default gen_random_uuid(),
  vehicle_id uuid not null references public.vehicles (id) on delete cascade,
  start_odometer integer not null,
  end_odometer integer,
  started_at timestamptz not null,
  ended_at timestamptz,
  purpose text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,

  constraint trips_start_odometer_check check (start_odometer >= 0),
  constraint trips_end_odometer_check
    check (end_odometer is null or end_odometer >= start_odometer),
  constraint trips_ended_at_check check (ended_at is null or ended_at >= started_at),
  constraint trips_completion_check
    check ((end_odometer is null) = (ended_at is null)),
  constraint trips_purpose_check
    check (purpose is null or char_length(btrim(purpose)) between 1 and 160)
);

create index trips_vehicle_started_idx
  on public.trips (vehicle_id, started_at desc)
  where deleted_at is null;

create trigger trips_set_updated_at
before update on public.trips
for each row execute function public.set_updated_at();

alter table public.trips enable row level security;
alter table public.trips force row level security;

revoke all on table public.trips from anon, authenticated;
grant select, insert, update, delete on table public.trips to authenticated;

create policy "trips_select_own"
on public.trips
for select
to authenticated
using (
  exists (
    select 1 from public.vehicles
    where vehicles.id = trips.vehicle_id
      and vehicles.user_id = (select auth.uid())
  )
);

create policy "trips_insert_own"
on public.trips
for insert
to authenticated
with check (
  exists (
    select 1 from public.vehicles
    where vehicles.id = trips.vehicle_id
      and vehicles.user_id = (select auth.uid())
      and vehicles.deleted_at is null
  )
);

create policy "trips_update_own"
on public.trips
for update
to authenticated
using (
  exists (
    select 1 from public.vehicles
    where vehicles.id = trips.vehicle_id
      and vehicles.user_id = (select auth.uid())
  )
)
with check (
  exists (
    select 1 from public.vehicles
    where vehicles.id = trips.vehicle_id
      and vehicles.user_id = (select auth.uid())
  )
);

create policy "trips_delete_own"
on public.trips
for delete
to authenticated
using (
  exists (
    select 1 from public.vehicles
    where vehicles.id = trips.vehicle_id
      and vehicles.user_id = (select auth.uid())
  )
);

create function public.validate_trip_odometer()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  v_event_date date;
begin
  if new.deleted_at is not null or new.end_odometer is null then
    return new;
  end if;

  v_event_date := coalesce(new.ended_at, new.started_at)::date;

  if v_event_date > current_date then
    raise exception 'Trip date cannot be in the future'
      using errcode = '23514';
  end if;

  if exists (
    select 1 from public.maintenances
    where vehicle_id = new.vehicle_id
      and deleted_at is null
      and maintenance_date < v_event_date
      and odometer > new.end_odometer
  ) or exists (
    select 1 from public.refuelings
    where vehicle_id = new.vehicle_id
      and deleted_at is null
      and refueling_date < v_event_date
      and odometer > new.end_odometer
  ) or exists (
    select 1 from public.trips
    where vehicle_id = new.vehicle_id
      and deleted_at is null
      and id <> new.id
      and end_odometer is not null
      and coalesce(ended_at, started_at)::date < v_event_date
      and end_odometer > new.end_odometer
  ) then
    raise exception 'Odometer cannot be lower than an earlier vehicle event'
      using errcode = '23514';
  end if;

  update public.vehicles
  set current_odometer = greatest(current_odometer, new.end_odometer)
  where id = new.vehicle_id
    and current_odometer < new.end_odometer;

  return new;
end;
$$;

revoke all on function public.validate_trip_odometer() from public, anon, authenticated;

create trigger trips_validate_odometer
before insert or update of vehicle_id, started_at, ended_at, end_odometer, deleted_at
on public.trips
for each row execute function public.validate_trip_odometer();

comment on table public.trips is
  'Diário de viagens do veículo; considerada encerrada quando ended_at/end_odometer são preenchidos.';
comment on function public.validate_trip_odometer() is
  'Ao encerrar uma viagem, valida cronologia contra outros eventos do veículo e avança o odômetro.';
