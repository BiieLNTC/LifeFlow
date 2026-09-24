create table public.vehicles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  vehicle_type text not null,
  nickname text not null,
  brand text not null,
  model text not null,
  version text,
  manufacture_year smallint,
  model_year smallint,
  license_plate text,
  fuel_type text,
  current_odometer integer not null default 0,
  purchase_date date,
  purchase_price numeric(14, 2),
  notes text,
  photo_path text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  last_synced_at timestamptz,

  constraint vehicles_vehicle_type_check
    check (vehicle_type in ('car', 'motorcycle')),
  constraint vehicles_nickname_check
    check (char_length(btrim(nickname)) between 1 and 80),
  constraint vehicles_brand_check
    check (char_length(btrim(brand)) between 1 and 80),
  constraint vehicles_model_check
    check (char_length(btrim(model)) between 1 and 80),
  constraint vehicles_version_check
    check (version is null or char_length(btrim(version)) between 1 and 100),
  constraint vehicles_manufacture_year_check
    check (manufacture_year is null or manufacture_year between 1886 and 2100),
  constraint vehicles_model_year_check
    check (
      model_year is null
      or model_year between 1886 and 2101
      and (manufacture_year is null or model_year between manufacture_year and manufacture_year + 1)
    ),
  constraint vehicles_license_plate_check
    check (license_plate is null or license_plate ~ '^[A-Z]{3}[0-9][A-Z0-9][0-9]{2}$'),
  constraint vehicles_fuel_type_check
    check (
      fuel_type is null
      or fuel_type in ('gasoline', 'ethanol', 'flex', 'diesel', 'electric', 'hybrid', 'other')
    ),
  constraint vehicles_current_odometer_check check (current_odometer >= 0),
  constraint vehicles_purchase_price_check check (purchase_price is null or purchase_price >= 0),
  constraint vehicles_notes_check check (notes is null or char_length(notes) <= 2000),
  constraint vehicles_deleted_state_check check (deleted_at is null or active = false)
);

create unique index vehicles_user_license_plate_unique
  on public.vehicles (user_id, license_plate)
  where license_plate is not null and deleted_at is null;

create index vehicles_user_active_updated_idx
  on public.vehicles (user_id, active, updated_at desc)
  where deleted_at is null;

create function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

revoke all on function public.set_updated_at() from public, anon, authenticated;

create trigger vehicles_set_updated_at
before update on public.vehicles
for each row execute function public.set_updated_at();

alter table public.vehicles enable row level security;
alter table public.vehicles force row level security;

revoke all on table public.vehicles from anon, authenticated;
grant select, insert, update on table public.vehicles to authenticated;

create policy "vehicles_select_own"
on public.vehicles
for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "vehicles_insert_own"
on public.vehicles
for insert
to authenticated
with check ((select auth.uid()) = user_id);

create policy "vehicles_update_own"
on public.vehicles
for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

comment on table public.vehicles is 'Veículos pertencentes a usuários autenticados do Motora.';
comment on column public.vehicles.photo_path is 'Caminho reservado para o milestone de Storage; não contém binário.';
