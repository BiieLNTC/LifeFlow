create table public.maintenances (
  id uuid primary key,
  vehicle_id uuid not null references public.vehicles (id) on delete cascade,
  maintenance_date date not null,
  odometer integer not null,
  maintenance_type text not null,
  workshop text,
  notes text,
  total_amount numeric(14, 2) not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  last_synced_at timestamptz,

  constraint maintenances_odometer_check check (odometer >= 0),
  constraint maintenances_type_check
    check (maintenance_type in ('preventive', 'corrective')),
  constraint maintenances_workshop_check
    check (workshop is null or char_length(btrim(workshop)) between 1 and 120),
  constraint maintenances_notes_check
    check (notes is null or char_length(notes) <= 2000),
  constraint maintenances_total_check check (total_amount >= 0)
);

create table public.maintenance_items (
  id uuid primary key,
  maintenance_id uuid not null references public.maintenances (id) on delete cascade,
  category text not null,
  description text not null,
  part_amount numeric(14, 2) not null default 0,
  labor_amount numeric(14, 2) not null default 0,
  next_replacement_odometer integer,
  next_replacement_date date,

  constraint maintenance_items_category_check check (
    category in (
      'oil', 'oil_filter', 'air_filter', 'fuel_filter', 'brakes', 'tires',
      'suspension', 'belts', 'battery', 'air_conditioning', 'alignment',
      'balancing', 'other'
    )
  ),
  constraint maintenance_items_description_check
    check (char_length(btrim(description)) between 1 and 160),
  constraint maintenance_items_part_amount_check check (part_amount >= 0),
  constraint maintenance_items_labor_amount_check check (labor_amount >= 0),
  constraint maintenance_items_next_odometer_check
    check (next_replacement_odometer is null or next_replacement_odometer >= 0)
);

create index maintenances_vehicle_date_idx
  on public.maintenances (vehicle_id, maintenance_date desc, created_at desc)
  where deleted_at is null;

create index maintenance_items_maintenance_idx
  on public.maintenance_items (maintenance_id);

create trigger maintenances_set_updated_at
before update on public.maintenances
for each row execute function public.set_updated_at();

alter table public.maintenances enable row level security;
alter table public.maintenances force row level security;
alter table public.maintenance_items enable row level security;
alter table public.maintenance_items force row level security;

revoke all on table public.maintenances from anon, authenticated;
revoke all on table public.maintenance_items from anon, authenticated;
grant select, insert, update on table public.maintenances to authenticated;
grant select, insert, update, delete on table public.maintenance_items to authenticated;

create policy "maintenances_select_own"
on public.maintenances for select to authenticated
using (
  exists (
    select 1 from public.vehicles
    where vehicles.id = maintenances.vehicle_id
      and vehicles.user_id = (select auth.uid())
      and vehicles.deleted_at is null
  )
);

create policy "maintenances_insert_own"
on public.maintenances for insert to authenticated
with check (
  exists (
    select 1 from public.vehicles
    where vehicles.id = maintenances.vehicle_id
      and vehicles.user_id = (select auth.uid())
      and vehicles.deleted_at is null
  )
);

create policy "maintenances_update_own"
on public.maintenances for update to authenticated
using (
  exists (
    select 1 from public.vehicles
    where vehicles.id = maintenances.vehicle_id
      and vehicles.user_id = (select auth.uid())
  )
)
with check (
  exists (
    select 1 from public.vehicles
    where vehicles.id = maintenances.vehicle_id
      and vehicles.user_id = (select auth.uid())
  )
);

create policy "maintenance_items_select_own"
on public.maintenance_items for select to authenticated
using (
  exists (
    select 1
    from public.maintenances
    join public.vehicles on vehicles.id = maintenances.vehicle_id
    where maintenances.id = maintenance_items.maintenance_id
      and maintenances.deleted_at is null
      and vehicles.user_id = (select auth.uid())
  )
);

create policy "maintenance_items_insert_own"
on public.maintenance_items for insert to authenticated
with check (
  exists (
    select 1
    from public.maintenances
    join public.vehicles on vehicles.id = maintenances.vehicle_id
    where maintenances.id = maintenance_items.maintenance_id
      and maintenances.deleted_at is null
      and vehicles.user_id = (select auth.uid())
  )
);

create policy "maintenance_items_update_own"
on public.maintenance_items for update to authenticated
using (
  exists (
    select 1
    from public.maintenances
    join public.vehicles on vehicles.id = maintenances.vehicle_id
    where maintenances.id = maintenance_items.maintenance_id
      and maintenances.deleted_at is null
      and vehicles.user_id = (select auth.uid())
  )
)
with check (
  exists (
    select 1
    from public.maintenances
    join public.vehicles on vehicles.id = maintenances.vehicle_id
    where maintenances.id = maintenance_items.maintenance_id
      and maintenances.deleted_at is null
      and vehicles.user_id = (select auth.uid())
  )
);

create policy "maintenance_items_delete_own"
on public.maintenance_items for delete to authenticated
using (
  exists (
    select 1
    from public.maintenances
    join public.vehicles on vehicles.id = maintenances.vehicle_id
    where maintenances.id = maintenance_items.maintenance_id
      and maintenances.deleted_at is null
      and vehicles.user_id = (select auth.uid())
  )
);

create function public.save_maintenance(
  p_id uuid,
  p_vehicle_id uuid,
  p_maintenance_date date,
  p_odometer integer,
  p_maintenance_type text,
  p_workshop text,
  p_notes text,
  p_items jsonb
)
returns uuid
language plpgsql
set search_path = ''
as $$
declare
  v_item jsonb;
  v_total numeric(14, 2) := 0;
begin
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'A maintenance must contain at least one item' using errcode = '23514';
  end if;

  for v_item in select value from jsonb_array_elements(p_items)
  loop
    if (v_item->>'next_replacement_odometer') is not null
       and (v_item->>'next_replacement_odometer')::integer <= p_odometer then
      raise exception 'Next replacement odometer must be greater than maintenance odometer'
        using errcode = '23514';
    end if;
    if (v_item->>'next_replacement_date') is not null
       and (v_item->>'next_replacement_date')::date <= p_maintenance_date then
      raise exception 'Next replacement date must be after maintenance date'
        using errcode = '23514';
    end if;
    v_total := v_total
      + coalesce((v_item->>'part_amount')::numeric, 0)
      + coalesce((v_item->>'labor_amount')::numeric, 0);
  end loop;

  insert into public.maintenances (
    id, vehicle_id, maintenance_date, odometer, maintenance_type,
    workshop, notes, total_amount, deleted_at
  ) values (
    p_id, p_vehicle_id, p_maintenance_date, p_odometer, p_maintenance_type,
    nullif(btrim(p_workshop), ''), nullif(btrim(p_notes), ''), v_total, null
  )
  on conflict (id) do update set
    vehicle_id = excluded.vehicle_id,
    maintenance_date = excluded.maintenance_date,
    odometer = excluded.odometer,
    maintenance_type = excluded.maintenance_type,
    workshop = excluded.workshop,
    notes = excluded.notes,
    total_amount = excluded.total_amount,
    deleted_at = null;

  delete from public.maintenance_items where maintenance_id = p_id;

  insert into public.maintenance_items (
    id, maintenance_id, category, description, part_amount, labor_amount,
    next_replacement_odometer, next_replacement_date
  )
  select
    (item->>'id')::uuid,
    p_id,
    item->>'category',
    btrim(item->>'description'),
    coalesce((item->>'part_amount')::numeric, 0),
    coalesce((item->>'labor_amount')::numeric, 0),
    (item->>'next_replacement_odometer')::integer,
    (item->>'next_replacement_date')::date
  from jsonb_array_elements(p_items) as item;

  return p_id;
end;
$$;

revoke all on function public.save_maintenance(uuid, uuid, date, integer, text, text, text, jsonb)
  from public, anon;
grant execute on function public.save_maintenance(uuid, uuid, date, integer, text, text, text, jsonb)
  to authenticated;

comment on table public.maintenances is 'Manutenções realizadas nos veículos do Motora.';
comment on table public.maintenance_items is 'Serviços e peças que compõem uma manutenção.';
