create function public.validate_vehicle_event_odometer()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  v_event_date date;
  v_record jsonb;
begin
  v_record := to_jsonb(new);
  v_event_date := coalesce(
    v_record->>'maintenance_date',
    v_record->>'refueling_date'
  )::date;

  if new.deleted_at is not null then
    return new;
  end if;

  perform 1
  from public.vehicles
  where id = new.vehicle_id
    and deleted_at is null
  for update;

  if not found then
    return new;
  end if;

  if v_event_date > current_date then
    raise exception 'Vehicle event date cannot be in the future'
      using errcode = '23514';
  end if;

  if exists (
    select 1
    from public.maintenances
    where vehicle_id = new.vehicle_id
      and deleted_at is null
      and maintenance_date < v_event_date
      and odometer > new.odometer
      and (tg_table_name <> 'maintenances' or id <> new.id)
  ) or exists (
    select 1
    from public.refuelings
    where vehicle_id = new.vehicle_id
      and deleted_at is null
      and refueling_date < v_event_date
      and odometer > new.odometer
      and (tg_table_name <> 'refuelings' or id <> new.id)
  ) then
    raise exception 'Odometer cannot be lower than an earlier vehicle event'
      using errcode = '23514';
  end if;

  if exists (
    select 1
    from public.maintenances
    where vehicle_id = new.vehicle_id
      and deleted_at is null
      and maintenance_date > v_event_date
      and odometer < new.odometer
      and (tg_table_name <> 'maintenances' or id <> new.id)
  ) or exists (
    select 1
    from public.refuelings
    where vehicle_id = new.vehicle_id
      and deleted_at is null
      and refueling_date > v_event_date
      and odometer < new.odometer
      and (tg_table_name <> 'refuelings' or id <> new.id)
  ) then
    raise exception 'Odometer cannot be higher than a later vehicle event'
      using errcode = '23514';
  end if;

  update public.vehicles
  set current_odometer = greatest(current_odometer, new.odometer)
  where id = new.vehicle_id
    and current_odometer < new.odometer;

  return new;
end;
$$;

revoke all on function public.validate_vehicle_event_odometer()
  from public, anon, authenticated;

create trigger maintenances_validate_odometer
before insert or update of vehicle_id, maintenance_date, odometer, deleted_at
on public.maintenances
for each row execute function public.validate_vehicle_event_odometer();

create trigger refuelings_validate_odometer
before insert or update of vehicle_id, refueling_date, odometer, deleted_at
on public.refuelings
for each row execute function public.validate_vehicle_event_odometer();

create function public.validate_domain_date_not_future()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  v_date date;
begin
  v_date := coalesce(
    to_jsonb(new)->>'purchase_date',
    to_jsonb(new)->>'expense_date'
  )::date;

  if v_date is not null and v_date > current_date then
    raise exception 'Domain date cannot be in the future'
      using errcode = '23514';
  end if;

  return new;
end;
$$;

revoke all on function public.validate_domain_date_not_future()
  from public, anon, authenticated;

create trigger vehicles_validate_purchase_date
before insert or update of purchase_date on public.vehicles
for each row execute function public.validate_domain_date_not_future();

create trigger expenses_validate_expense_date
before insert or update of expense_date on public.expenses
for each row execute function public.validate_domain_date_not_future();

comment on function public.validate_vehicle_event_odometer() is
  'Validates event chronology and advances the vehicle odometer atomically.';
