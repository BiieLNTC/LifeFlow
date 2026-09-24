create table public.refuelings (
  id uuid primary key,
  vehicle_id uuid not null references public.vehicles (id) on delete cascade,
  refueling_date date not null,
  odometer integer not null,
  liters numeric(10, 3) not null,
  unit_price numeric(10, 4) not null,
  total_amount numeric(14, 2) not null,
  fuel_type text not null,
  full_tank boolean not null default false,
  gas_station text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  last_synced_at timestamptz,

  constraint refuelings_odometer_check check (odometer >= 0),
  constraint refuelings_liters_check check (liters > 0),
  constraint refuelings_unit_price_check check (unit_price > 0),
  constraint refuelings_total_check check (total_amount > 0),
  constraint refuelings_calculation_check
    check (abs(total_amount - round(liters * unit_price, 2)) <= 0.01),
  constraint refuelings_fuel_type_check check (
    fuel_type in ('gasoline', 'ethanol', 'flex', 'diesel', 'electric', 'hybrid', 'other')
  ),
  constraint refuelings_station_check
    check (gas_station is null or char_length(btrim(gas_station)) between 1 and 120),
  constraint refuelings_notes_check check (notes is null or char_length(notes) <= 2000)
);

create index refuelings_vehicle_date_idx
  on public.refuelings (vehicle_id, refueling_date desc, odometer desc)
  where deleted_at is null;

create trigger refuelings_set_updated_at
before update on public.refuelings
for each row execute function public.set_updated_at();

alter table public.refuelings enable row level security;
alter table public.refuelings force row level security;
revoke all on table public.refuelings from anon, authenticated;
grant select, insert, update on table public.refuelings to authenticated;

create policy "refuelings_select_own" on public.refuelings
for select to authenticated using (
  exists (select 1 from public.vehicles
    where vehicles.id = refuelings.vehicle_id
      and vehicles.user_id = (select auth.uid()))
);
create policy "refuelings_insert_own" on public.refuelings
for insert to authenticated with check (
  exists (select 1 from public.vehicles
    where vehicles.id = refuelings.vehicle_id
      and vehicles.user_id = (select auth.uid())
      and vehicles.deleted_at is null)
);
create policy "refuelings_update_own" on public.refuelings
for update to authenticated
using (exists (select 1 from public.vehicles
  where vehicles.id = refuelings.vehicle_id and vehicles.user_id = (select auth.uid())))
with check (exists (select 1 from public.vehicles
  where vehicles.id = refuelings.vehicle_id and vehicles.user_id = (select auth.uid())));

create view public.refueling_details
with (security_invoker = true)
as
with full_cycles as (
  select id, vehicle_id, odometer,
    lag(odometer) over (partition by vehicle_id order by odometer, refueling_date, created_at) as previous_full_odometer
  from public.refuelings
  where full_tank and deleted_at is null
)
select r.*,
  case
    when c.previous_full_odometer is not null and r.odometer > c.previous_full_odometer then
      round(
        (r.odometer - c.previous_full_odometer)::numeric /
        nullif((select sum(x.liters) from public.refuelings x
          where x.vehicle_id = r.vehicle_id and x.deleted_at is null
            and x.odometer > c.previous_full_odometer and x.odometer <= r.odometer), 0),
        2
      )
    else null
  end as consumption_km_l
from public.refuelings r
left join full_cycles c on c.id = r.id
where r.deleted_at is null;

revoke all on public.refueling_details from anon, authenticated;
grant select on public.refueling_details to authenticated;
comment on view public.refueling_details is 'Abastecimentos com consumo calculado apenas em ciclos completos de tanque cheio.';
