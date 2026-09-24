create function public.get_or_create_vehicle_category(p_user_id uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_category_id uuid;
begin
  select id into v_category_id
  from public.categories
  where user_id = p_user_id
    and deleted_at is null
    and lower(description) = lower('Veículo')
  limit 1;

  if v_category_id is null then
    insert into public.categories (user_id, description, purpose)
    values (p_user_id, 'Veículo', 'expense')
    returning id into v_category_id;
  end if;

  return v_category_id;
end;
$$;

revoke all on function public.get_or_create_vehicle_category(uuid) from public, anon, authenticated;

comment on function public.get_or_create_vehicle_category(uuid) is
  'Retorna a categoria "Veículo" do usuário, criando-a de forma preguiçosa se necessário. '
  'SECURITY DEFINER: chamada só pelos triggers de sincronização veículo->transação.';

create function public.sync_maintenance_transaction()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;
  v_category_id uuid;
begin
  if tg_op = 'DELETE' then
    delete from public.transactions
    where source_type = 'maintenance' and source_id = old.id;
    return old;
  end if;

  if new.deleted_at is not null or new.total_amount <= 0 then
    delete from public.transactions
    where source_type = 'maintenance' and source_id = new.id;
    return new;
  end if;

  select user_id into v_user_id from public.vehicles where id = new.vehicle_id;
  v_category_id := public.get_or_create_vehicle_category(v_user_id);

  insert into public.transactions (
    user_id, category_id, transaction_date, description, type, amount,
    source_type, source_id
  ) values (
    v_user_id, v_category_id, new.maintenance_date, 'Manutenção',
    'expense', new.total_amount, 'maintenance', new.id
  )
  on conflict (source_id) where source_type = 'maintenance' do update set
    user_id = excluded.user_id,
    category_id = excluded.category_id,
    transaction_date = excluded.transaction_date,
    amount = excluded.amount;

  return new;
end;
$$;

revoke all on function public.sync_maintenance_transaction() from public, anon, authenticated;

create trigger maintenances_sync_transaction
after insert or update of maintenance_date, total_amount, vehicle_id, deleted_at or delete
on public.maintenances
for each row execute function public.sync_maintenance_transaction();

create function public.sync_refueling_transaction()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;
  v_category_id uuid;
begin
  if tg_op = 'DELETE' then
    delete from public.transactions
    where source_type = 'refueling' and source_id = old.id;
    return old;
  end if;

  if new.deleted_at is not null then
    delete from public.transactions
    where source_type = 'refueling' and source_id = new.id;
    return new;
  end if;

  select user_id into v_user_id from public.vehicles where id = new.vehicle_id;
  v_category_id := public.get_or_create_vehicle_category(v_user_id);

  insert into public.transactions (
    user_id, category_id, transaction_date, description, type, amount,
    source_type, source_id
  ) values (
    v_user_id, v_category_id, new.refueling_date, 'Abastecimento',
    'expense', new.total_amount, 'refueling', new.id
  )
  on conflict (source_id) where source_type = 'refueling' do update set
    user_id = excluded.user_id,
    category_id = excluded.category_id,
    transaction_date = excluded.transaction_date,
    amount = excluded.amount;

  return new;
end;
$$;

revoke all on function public.sync_refueling_transaction() from public, anon, authenticated;

create trigger refuelings_sync_transaction
after insert or update of refueling_date, total_amount, vehicle_id, deleted_at or delete
on public.refuelings
for each row execute function public.sync_refueling_transaction();

create function public.sync_vehicle_expense_transaction()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;
  v_category_id uuid;
begin
  if tg_op = 'DELETE' then
    delete from public.transactions
    where source_type = 'vehicle_expense' and source_id = old.id;
    return old;
  end if;

  if new.deleted_at is not null then
    delete from public.transactions
    where source_type = 'vehicle_expense' and source_id = new.id;
    return new;
  end if;

  select user_id into v_user_id from public.vehicles where id = new.vehicle_id;
  v_category_id := public.get_or_create_vehicle_category(v_user_id);

  insert into public.transactions (
    user_id, category_id, transaction_date, description, type, amount,
    source_type, source_id
  ) values (
    v_user_id, v_category_id, new.expense_date, new.description,
    'expense', new.amount, 'vehicle_expense', new.id
  )
  on conflict (source_id) where source_type = 'vehicle_expense' do update set
    user_id = excluded.user_id,
    category_id = excluded.category_id,
    transaction_date = excluded.transaction_date,
    description = excluded.description,
    amount = excluded.amount;

  return new;
end;
$$;

revoke all on function public.sync_vehicle_expense_transaction() from public, anon, authenticated;

create trigger expenses_sync_transaction
after insert or update of expense_date, amount, description, vehicle_id, deleted_at or delete
on public.expenses
for each row execute function public.sync_vehicle_expense_transaction();

comment on function public.sync_maintenance_transaction() is
  'SECURITY DEFINER: espelha manutenções em transactions (source_type=maintenance), bypassando o bloqueio de RLS em transações de origem. '
  'Ignora total_amount <= 0 (manutenção ainda sem itens) para não violar transactions_amount_check.';
comment on function public.sync_refueling_transaction() is
  'SECURITY DEFINER: espelha abastecimentos em transactions (source_type=refueling).';
comment on function public.sync_vehicle_expense_transaction() is
  'SECURITY DEFINER: espelha despesas de veículo em transactions (source_type=vehicle_expense).';
