insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
) values (
  'vehicle-attachments',
  'vehicle-attachments',
  false,
  10485760,
  array['image/jpeg', 'image/png', 'application/pdf']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create table public.attachments (
  id uuid primary key,
  vehicle_id uuid not null references public.vehicles (id) on delete cascade,
  entity_type text not null,
  entity_id uuid not null,
  file_name text not null,
  content_type text not null,
  file_size bigint not null,
  storage_path text not null unique,
  created_at timestamptz not null default now(),
  created_by uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  deleted_at timestamptz,

  constraint attachments_entity_type_check
    check (entity_type = 'maintenance'),
  constraint attachments_entity_fk
    foreign key (entity_id, vehicle_id)
    references public.maintenances (id, vehicle_id),
  constraint attachments_file_name_check
    check (char_length(btrim(file_name)) between 1 and 255),
  constraint attachments_content_type_check
    check (content_type in ('image/jpeg', 'image/png', 'application/pdf')),
  constraint attachments_file_size_check
    check (file_size between 1 and 10485760),
  constraint attachments_storage_path_check check (
    storage_path like
      'users/' || created_by::text
      || '/vehicles/' || vehicle_id::text
      || '/maintenance/' || entity_id::text
      || '/' || id::text || '.%'
  )
);

create index attachments_entity_created_idx
  on public.attachments (entity_type, entity_id, created_at desc)
  where deleted_at is null;

alter table public.attachments enable row level security;
alter table public.attachments force row level security;
revoke all on table public.attachments from anon, authenticated;
grant select, insert, update on table public.attachments to authenticated;

create policy "attachments_select_own" on public.attachments
for select to authenticated using (
  created_by = (select auth.uid())
  and exists (
    select 1 from public.vehicles
    where vehicles.id = attachments.vehicle_id
      and vehicles.user_id = (select auth.uid())
  )
);

create policy "attachments_insert_own" on public.attachments
for insert to authenticated with check (
  created_by = (select auth.uid())
  and exists (
    select 1 from public.vehicles
    where vehicles.id = attachments.vehicle_id
      and vehicles.user_id = (select auth.uid())
      and vehicles.deleted_at is null
  )
  and exists (
    select 1 from public.maintenances
    where maintenances.id = attachments.entity_id
      and maintenances.vehicle_id = attachments.vehicle_id
      and maintenances.deleted_at is null
  )
);

create policy "attachments_update_own" on public.attachments
for update to authenticated
using (
  created_by = (select auth.uid())
  and exists (
    select 1 from public.vehicles
    where vehicles.id = attachments.vehicle_id
      and vehicles.user_id = (select auth.uid())
  )
)
with check (
  created_by = (select auth.uid())
  and exists (
    select 1 from public.vehicles
    where vehicles.id = attachments.vehicle_id
      and vehicles.user_id = (select auth.uid())
  )
);

create policy "vehicle_attachments_select_own"
on storage.objects for select to authenticated
using (
  bucket_id = 'vehicle-attachments'
  and (storage.foldername(name))[1] = 'users'
  and (storage.foldername(name))[2] = (select auth.uid())::text
  and (storage.foldername(name))[3] = 'vehicles'
  and exists (
    select 1 from public.vehicles
    where vehicles.id::text = (storage.foldername(name))[4]
      and vehicles.user_id = (select auth.uid())
  )
);

create policy "vehicle_attachments_insert_own"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'vehicle-attachments'
  and (storage.foldername(name))[1] = 'users'
  and (storage.foldername(name))[2] = (select auth.uid())::text
  and (storage.foldername(name))[3] = 'vehicles'
  and (storage.foldername(name))[5] = 'maintenance'
  and exists (
    select 1
    from public.maintenances
    join public.vehicles on vehicles.id = maintenances.vehicle_id
    where vehicles.id::text = (storage.foldername(name))[4]
      and maintenances.id::text = (storage.foldername(name))[6]
      and vehicles.user_id = (select auth.uid())
      and vehicles.deleted_at is null
      and maintenances.deleted_at is null
  )
);

create policy "vehicle_attachments_delete_own"
on storage.objects for delete to authenticated
using (
  bucket_id = 'vehicle-attachments'
  and (storage.foldername(name))[1] = 'users'
  and (storage.foldername(name))[2] = (select auth.uid())::text
  and (storage.foldername(name))[3] = 'vehicles'
  and exists (
    select 1 from public.vehicles
    where vehicles.id::text = (storage.foldername(name))[4]
      and vehicles.user_id = (select auth.uid())
  )
);

comment on table public.attachments is
  'Metadados de anexos privados; binarios permanecem no Supabase Storage.';
