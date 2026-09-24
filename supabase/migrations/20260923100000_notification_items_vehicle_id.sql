-- M6: vehicle_id permite abrir o veículo de um lembrete/documento a partir da central.
create or replace view public.notification_items
with (security_invoker = true)
as
select
  'reminder'::text as kind,
  reminder_details.description as title,
  case reminder_details.visual_status
    when 'overdue' then 'Vencido'
    else 'Vence em breve'
  end as subtitle,
  case reminder_details.visual_status
    when 'overdue' then 'critical'
    else 'warning'
  end as severity,
  'reminder'::text as target_type,
  reminder_details.id as target_id,
  reminder_details.target_date as due_date,
  reminder_details.vehicle_id as vehicle_id
from public.reminder_details
where reminder_details.status = 'active'
  and reminder_details.visual_status in ('near', 'overdue')

union all

select
  'budget'::text,
  budget_progress.category_description,
  case budget_progress.status
    when 'critical' then 'Orçamento estourado'
    else 'Orçamento próximo do limite'
  end,
  budget_progress.status,
  'budget'::text,
  budget_progress.budget_id,
  (make_date(budget_progress.year, budget_progress.month, 1) + interval '1 month' - interval '1 day')::date,
  null::uuid
from public.budget_progress
where budget_progress.status in ('warning', 'critical')

union all

select
  'vehicle_document'::text,
  vehicle_documents.description,
  case
    when vehicle_documents.expiry_date <= current_date then 'Vencido'
    else 'Vence em breve'
  end,
  case
    when vehicle_documents.expiry_date <= current_date then 'critical'
    else 'warning'
  end,
  'vehicle_document'::text,
  vehicle_documents.id,
  vehicle_documents.expiry_date,
  vehicle_documents.vehicle_id
from public.vehicle_documents
where vehicle_documents.deleted_at is null
  and vehicle_documents.expiry_date is not null
  and vehicle_documents.expiry_date - current_date <= 30

union all

select
  'recurring_transaction'::text,
  recurring_transactions.description,
  'Lançamento recorrente pendente de geração'::text,
  'info'::text,
  'recurring_transaction'::text,
  recurring_transactions.id,
  (date_trunc('month', current_date) + (recurring_transactions.day_of_month - 1) * interval '1 day')::date,
  null::uuid
from public.recurring_transactions
where recurring_transactions.deleted_at is null
  and not recurring_transactions.paused
  and recurring_transactions.start_date
    <= (date_trunc('month', current_date) + (recurring_transactions.day_of_month - 1) * interval '1 day')::date
  and (
    recurring_transactions.end_date is null
    or recurring_transactions.end_date
      >= (date_trunc('month', current_date) + (recurring_transactions.day_of_month - 1) * interval '1 day')::date
  )
  and (date_trunc('month', current_date) + (recurring_transactions.day_of_month - 1) * interval '1 day')::date
    <= current_date
  and not exists (
    select 1 from public.transactions
    where transactions.source_type = 'recurring'
      and transactions.source_id = recurring_transactions.id
      and transactions.transaction_date
        = (date_trunc('month', current_date) + (recurring_transactions.day_of_month - 1) * interval '1 day')::date
  );

comment on view public.notification_items is
  'Central de notificações unificada: lembretes vencendo/vencidos, orçamentos >=80%, documentos de veículo vencendo e recorrências pendentes de geração. vehicle_id (lembretes e documentos) permite o deep link para o veículo.';
