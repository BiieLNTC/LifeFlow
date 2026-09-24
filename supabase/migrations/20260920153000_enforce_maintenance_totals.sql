create function public.set_maintenance_total()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  select coalesce(sum(part_amount + labor_amount), 0)
  into new.total_amount
  from public.maintenance_items
  where maintenance_id = new.id;
  return new;
end;
$$;

create function public.refresh_maintenance_total()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  v_maintenance_id uuid := coalesce(new.maintenance_id, old.maintenance_id);
begin
  update public.maintenances
  set total_amount = (
    select coalesce(sum(part_amount + labor_amount), 0)
    from public.maintenance_items
    where maintenance_id = v_maintenance_id
  )
  where id = v_maintenance_id;

  if tg_op = 'UPDATE' and old.maintenance_id <> new.maintenance_id then
    update public.maintenances
    set total_amount = (
      select coalesce(sum(part_amount + labor_amount), 0)
      from public.maintenance_items
      where maintenance_id = old.maintenance_id
    )
    where id = old.maintenance_id;
  end if;

  return null;
end;
$$;

revoke all on function public.set_maintenance_total() from public, anon, authenticated;
revoke all on function public.refresh_maintenance_total() from public, anon, authenticated;

create trigger maintenances_protect_total
before insert or update of total_amount on public.maintenances
for each row execute function public.set_maintenance_total();

create trigger maintenance_items_refresh_total
after insert or update of part_amount, labor_amount, maintenance_id or delete
on public.maintenance_items
for each row execute function public.refresh_maintenance_total();
