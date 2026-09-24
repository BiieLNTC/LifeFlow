# LifeFlow — Roadmap detalhado

Este documento detalha, milestone a milestone, o trabalho definido em `AGENTS.md` §13. Cada milestone é uma unidade fechável (compila, testa, `flutter analyze`/lint limpo) antes de seguir para a próxima. Não pular milestones nem antecipar escopo de um milestone futuro.

Convenção de nomenclatura no schema: inglês, `snake_case`, seguindo o que já existe em `vehicles`/`maintenances` etc.

---

## M1 — Schema de Finanças (Supabase)

### 1.1 `categories`
`id uuid pk, user_id uuid, description text, purpose text check in ('expense','income','both'), color text, created_at, updated_at, deleted_at`. RLS por `user_id = auth.uid()`. Índice único `(user_id, lower(description))` para ativos.

### 1.2 `people`
`id uuid pk, user_id uuid, name text, birth_date date, created_at, updated_at, deleted_at`. RLS igual.

### 1.3 `transactions`
`id uuid pk, user_id uuid, category_id uuid fk, person_id uuid fk nullable, transaction_date date, description text, type text check in ('expense','income'), amount numeric(14,2) check > 0, source_type text nullable, source_id uuid nullable, installment_group_id uuid nullable, installment_index int nullable, installment_total int nullable, created_at, updated_at, deleted_at`. RLS por `user_id`. Índice em `(user_id, transaction_date)` e em `(source_type, source_id)`.

`source_type`/`source_id` identificam a origem quando a transação foi gerada automaticamente (`'maintenance'`, `'refueling'`, `'vehicle_expense'`, `'recurring'`). Quando preenchido, a transação **não é editável/excluível diretamente pelo client de finanças** — só pela origem. Enforçar isso via RLS (`UPDATE`/`DELETE` policy exige `source_type is null`) mais validação de UI.

### 1.4 `budgets`
`id uuid pk, user_id uuid, category_id uuid fk, year int, month int, limit_amount numeric(14,2), created_at, updated_at, deleted_at`. Único `(user_id, category_id, year, month)` entre ativos. RLS por `user_id`.

### 1.5 `recurring_transactions`
`id uuid pk, user_id uuid, category_id uuid fk, person_id uuid fk nullable, description text, type text, amount numeric(14,2), day_of_month int check 1-28, start_date date, end_date date nullable, paused boolean default false, created_at, updated_at, deleted_at`. RLS por `user_id`.

Geração sob demanda: função `generate_due_recurring_transactions()` (`SECURITY INVOKER`, roda com a sessão do usuário) — para cada `recurring_transactions` ativa do usuário, insere em `transactions` (com `source_type = 'recurring'`, `source_id = recurring_transactions.id`) as ocorrências entre a última gerada e a data atual, respeitando `day_of_month`/`end_date`. Chamada pelo client (Flutter/Next.js) ao abrir a tela de finanças — nunca em cron.

### 1.6 `savings_goals` + `goal_contributions`
`savings_goals: id uuid pk, user_id uuid, title text, target_amount numeric(14,2), target_date date nullable, created_at, updated_at, deleted_at`.
`goal_contributions: id uuid pk, goal_id uuid fk, transaction_id uuid fk nullable, amount numeric(14,2), contribution_date date, created_at`. Um aporte pode opcionalmente estar ligado a uma transação de despesa (ex: transferência pra poupança) — decisão de vincular ou não fica com o usuário no formulário, não automática.

### 1.7 Parcelamento
Sem tabela própria: uma compra parcelada gera N linhas em `transactions` com o mesmo `installment_group_id`, `installment_index` (1..N) e `installment_total`, datadas em meses consecutivos a partir da data da compra. Editar/excluir uma parcela isolada não afeta as demais (diferente de recorrência, que tem modelo único).

### 1.8 Views/functions agregadas
- `finance_totals(user)`: saldo total, receitas/despesas do mês corrente.
- `finance_totals_by_category`, `finance_totals_by_person`.
- `finance_top_expenses`, `finance_top_income`.
- `budget_progress`: por categoria/mês, `limit_amount`, gasto real (via `transactions`), percentual, status (verde <80%, âmbar 80–99%, vermelho ≥100% — mesmo padrão de lembretes de veículo).
- `finance_monthly_evolution`: receitas/despesas por mês, últimos 12 meses.
Todas `security_invoker = true`.

### 1.9 Vínculo veículo → transação automática
Trigger `AFTER INSERT/UPDATE/DELETE` em `maintenances`, `refuelings`, `expenses` (despesas de veículo) que faz `upsert`/`delete` na `transactions` correspondente (`source_type`/`source_id` apontando pro registro de veículo, `category_id` = categoria fixa "Veículo" do usuário).

Pré-requisito: toda conta precisa de uma categoria "Veículo" — criada automaticamente (trigger `AFTER INSERT` em `auth.users`, ou lazy no primeiro evento de veículo). Decisão: lazy, dentro do próprio trigger de sincronização (evita lógica extra no signup).

### 1.10 `vehicle_documents`
`id uuid pk, vehicle_id uuid fk, type text, description text, issue_date date nullable, expiry_date date nullable, created_at, updated_at, deleted_at`. RLS via `exists` no veículo (mesmo padrão de `maintenance_items`). Distinto de `attachments` (que guarda arquivo; aqui é só metadado de vencimento — pode referenciar um `attachment_id` opcional no futuro).

### 1.11 `trips` (diário de viagens)
`id uuid pk, vehicle_id uuid fk, start_odometer numeric, end_odometer numeric check >= start_odometer, started_at timestamptz, ended_at timestamptz nullable, purpose text nullable, created_at, updated_at, deleted_at`. RLS via veículo. Ao concluir uma viagem, mesmo trigger de consistência de odômetro do Motora (§61 do AGENTS antigo) deve considerar `end_odometer`.

### 1.12 Central de notificações
Sem tabela própria — view `notification_items` unindo: lembretes vencendo/vencidos (`reminder_details`), orçamentos ≥80% (`budget_progress`), documentos de veículo vencendo (`vehicle_documents`), recorrências pendentes de geração. Cada linha: `kind, title, subtitle, severity (info|warning|critical), target_type, target_id, due_date`.

### Testes (pgTAP)
Uma suíte por tabela nova (constraints + RLS + isolamento entre usuários), mais testes de function para `budget_progress`, `finance_totals`, `generate_due_recurring_transactions`, e do trigger de sincronização veículo→transação (criar manutenção, checar transação espelho; excluir manutenção, checar remoção).

**Entregável do M1**: migrations + testes passando. Nenhuma UI ainda.

---

## M2 — Finanças no Flutter

`lib/features/finance/` espelhando a estrutura de `features/vehicles` (`domain/`, `data/`, `presentation/`).

- 2.1 Modelos e repositórios: `Category`, `Person`, `Transaction`, `Budget`, `RecurringTransaction`, `SavingsGoal`, com `*Repository` (contrato em `domain/`, Supabase em `data/`).
- 2.2 Controllers Riverpod: listas, formulários, totais (consumindo as views do M1).
- 2.3 Offline: estender Drift (`cached_records`/`pending_mutations`) para as novas entidades, mesmo padrão do Motora.
- 2.4 Telas: Home (card de saldo + veículo, já prototipado), Finanças (saldo, orçamentos, meta, transações), formulário de transação (com toggle parcelamento/recorrência), tela de meta, gerenciamento de categorias/pessoas (dentro de "Mais").
- 2.5 Tela "Mais": perfil, Aparência (`ThemeMode` system/light/dark com persistência local), Categorias, Pessoas, Transações recorrentes, Sincronização, Exportar dados (pode ficar como placeholder desabilitado neste milestone), Sair.
- 2.6 Quick-add: bottom sheet unificado (Veículo + Finanças), já prototipado.
- 2.7 Ajustar navegação inferior para incluir Finanças sem quebrar os 5 slots (Início, Finanças, +, Veículos, Mais — como no protótipo).

**Entregável do M2**: `flutter analyze` limpo, testes de controllers/repositories, fluxo completo de registro de transação/orçamento/meta funcionando local + Supabase, offline coberto.

---

## M3 — Fundação do Next.js

- 3.1 Supabase Auth: login, cadastro, recuperação de senha (via `@supabase/ssr`, cookies httpOnly, PKCE).
- 3.2 Layout base: sidebar desktop (prototipada), adaptação mobile-web (bottom nav, reaproveitando os mesmos componentes visuais do protótipo).
- 3.3 Tema: tokens Tailwind portados de `app_colors.dart`, `prefers-color-scheme` + toggle manual persistido (mesmo modelo do Flutter: system/light/dark), tela de Configurações espelhando a do mobile.
- 3.4 Camada de dados: client Supabase tipado (gerar tipos via `supabase gen types typescript`), hooks React Query (ou SWR) por entidade.

**Entregável do M3**: app autentica, navega entre telas vazias/placeholder com o layout final, tema funcional.

---

## M4 — Finanças no Web

Reconstrução das telas de transações/categorias/pessoas do `granaflowapp` original (reaproveitando componentes shadcn/ui já existentes onde fizer sentido), ligadas ao schema do M1 em vez do `api-client.ts`/.NET. Mesmo escopo funcional do M2, adaptado a mouse/teclado (tabelas em vez de listas quando fizer sentido no desktop).

---

## M5 — Veículos no Web

Módulo novo (não existe hoje no GranaFlow): veículos, manutenções, abastecimentos, despesas de veículo, lembretes, documentos, diário de viagens, timeline, dashboard — paridade funcional com o Flutter.

---

## M6 — Central de notificações + unificação de UX

- 6.1 Tela de notificações (mobile + web) consumindo `notification_items`.
- 6.2 Badge de contagem no sino (já prototipado).
- 6.3 Revisão final de IA de navegação entre os dois clients, ajuste de qualquer inconsistência encontrada durante M2–M5.

---

## M7 — Polimento e deploy

- 7.1 Deploy web na Vercel (build estático padrão Next.js).
- 7.2 Build mobile (APK assinado / preparação iOS).
- 7.3 Atualizar `AGENTS.md`/`README.md` com estado real pós-implementação.
- 7.4 Revisar pendência do rename `motora_app` → pacote definitivo (ver README) — decidir se vale a pena nesse ponto ou se fica pra depois.
- 7.5 Decisão sobre os repositórios antigos (Motora, granaflowapp, GranaFlowAPI) — arquivar ou manter, conforme o usuário decidir na hora.

---

## Ordem de execução

M1 → M2 → M3 → M4 → M5 → M6 → M7, sequencial. M2 não começa sem M1 fechado (schema é pré-requisito). M4/M5 não começam sem M3 (fundação). Dentro de cada milestone, sub-itens podem ser paralelizados quando não há dependência direta (ex: 1.1–1.3 antes de 1.9, que depende delas).
