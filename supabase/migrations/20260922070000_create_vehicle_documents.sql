create table public.vehicle_documents (
  id uuid primary key default gen_random_uuid(),
  vehicle_id uuid not null references public.vehicles (id) on delete cascade,
  type text not null,
  description text not null,
  issue_date date,
  expiry_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,

  constraint vehicle_documents_type_check
    check (type in ('insurance', 'licensing', 'inspection', 'other')),
  constraint vehicle_documents_description_check
    check (char_length(btrim(description)) between 1 and 160),
  constraint vehicle_documents_issue_date_check
    check (issue_date is null or issue_date <= current_date),
  constraint vehicle_documents_dates_check
    check (issue_date is null or expiry_date is null or expiry_date >= issue_date)
);

create index vehicle_documents_vehicle_expiry_idx
  on public.vehicle_documents (vehicle_id, expiry_date)
  where deleted_at is null;

create trigger vehicle_documents_set_updated_at
before update on public.vehicle_documents
for each row execute function public.set_updated_at();

alter table public.vehicle_documents enable row level security;
alter table public.vehicle_documents force row level security;

revoke all on table public.vehicle_documents from anon, authenticated;
grant select, insert, update, delete on table public.vehicle_documents to authenticated;

create policy "vehicle_documents_select_own"
on public.vehicle_documents
for select
to authenticated
using (
  exists (
    select 1 from public.vehicles
    where vehicles.id = vehicle_documents.vehicle_id
      and vehicles.user_id = (select auth.uid())
  )
);

create policy "vehicle_documents_insert_own"
on public.vehicle_documents
for insert
to authenticated
with check (
  exists (
    select 1 from public.vehicles
    where vehicles.id = vehicle_documents.vehicle_id
      and vehicles.user_id = (select auth.uid())
      and vehicles.deleted_at is null
  )
);

create policy "vehicle_documents_update_own"
on public.vehicle_documents
for update
to authenticated
using (
  exists (
    select 1 from public.vehicles
    where vehicles.id = vehicle_documents.vehicle_id
      and vehicles.user_id = (select auth.uid())
  )
)
with check (
  exists (
    select 1 from public.vehicles
    where vehicles.id = vehicle_documents.vehicle_id
      and vehicles.user_id = (select auth.uid())
  )
);

create policy "vehicle_documents_delete_own"
on public.vehicle_documents
for delete
to authenticated
using (
  exists (
    select 1 from public.vehicles
    where vehicles.id = vehicle_documents.vehicle_id
      and vehicles.user_id = (select auth.uid())
  )
);

comment on table public.vehicle_documents is
  'Metadados de vencimento de documentos do veículo (seguro, licenciamento etc); não guarda o arquivo em si.';
