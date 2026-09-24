# LIFEFLOW — PROJECT MASTER SPECIFICATION

## 1. VISÃO DO PRODUTO

Nome: LifeFlow

O LifeFlow centraliza duas áreas da vida do usuário num produto só:

- **Veículos** (herdado do Motora): prontuário digital do veículo — quilometragem, manutenções, abastecimentos, despesas, lembretes, documentos, histórico, custo de propriedade.
- **Finanças** (herdado do GranaFlow): controle financeiro pessoal — transações, categorias, pessoas vinculadas, saldo, indicadores por categoria/pessoa.

A experiência deve responder rapidamente perguntas como:

- Quanto meu veículo está me custando?
- Quando preciso trocar o óleo novamente?
- Quanto eu gastei este mês, e com o quê?
- Qual é o meu saldo agora?

Mercado inicial: Brasil. Idioma: pt-BR. Moeda: BRL. Distância: km.

## 2. PRINCÍPIOS DO PRODUTO

1. Registro rápido.
2. Interface simples.
3. Histórico confiável.
4. Funcionamento offline (mobile).
5. Segurança.
6. Poucos campos obrigatórios.
7. Informações importantes facilmente visíveis.

O aplicativo NÃO deve parecer ERP, sistema administrativo ou planilha.

## 3. STACK

MOBILE (Flutter — `mobile/lifeflow_app`)

- Flutter, Dart, Riverpod, GoRouter
- Supabase Flutter SDK para Auth, PostgreSQL, Storage e Functions
- Drift + SQLite para cache e fila offline

WEB (Next.js — `web/lifeflow_web`)

- Next.js (App Router), TypeScript, Tailwind CSS, shadcn/ui
- `@supabase/ssr` / `@supabase/supabase-js` para Auth, PostgREST e Storage — sem API intermediária
- React Hook Form + Zod para formulários

BACKEND / PLATAFORMA (Supabase — `supabase/`)

- PostgreSQL, Auth, Storage, Row Level Security (RLS)
- Database Functions e Views para agregações (nunca montar agregados juntando múltiplas chamadas no client)
- Edge Functions com Deno/TypeScript somente quando necessárias
- Supabase CLI e migrations SQL versionadas

Não adicionar tecnologias sem necessidade. Não recriar um backend .NET ou API intermediária: Supabase é o único backend.

## 4. ARQUITETURA GERAL

```
Flutter ─┐                       ┌─ PostgreSQL + RLS
         ├─ Supabase SDK/JS ──►  ├─ Auth
Next.js ─┘   sessão/JWT          ├─ Storage + policies
                                 ├─ Database Functions / Views
                                 └─ Edge Functions quando necessárias
```

Tanto o Flutter quanto o Next.js acessam dados de negócio diretamente via SDK/PostgREST, usando somente a chave publishable/anon e a sessão autenticada do usuário. Nunca a `service_role`.

Toda tabela de negócio exposta a qualquer client deve ter RLS habilitado e forçado, com policies explícitas por operação. RLS é a única fronteira de autorização — filtros feitos no client nunca são considerados segurança.

## 5. SEGURANÇA

Nunca:

- armazenar senha manualmente ou implementar hash/JWT/refresh token próprio (Supabase Auth cobre isso nos dois clients);
- colocar a `service_role` no Flutter, no Next.js (client-side) ou no repositório;
- confiar em `user_id`/`UsuarioId` enviado pelo cliente — sempre `auth.uid()` no banco.

Funções `SECURITY DEFINER` são exceção, com `search_path` seguro e testes específicos. Buckets privados com policies coerentes. Um usuário nunca acessa recursos de outro.

## 6. IDENTIFICADORES

UUID em toda entidade nova (inclusive as portadas do GranaFlow, que usavam `int` — a troca para UUID é obrigatória na migração, pois o mobile precisa gerar IDs offline antes de existir registro no servidor).

## 7. DATAS E VALORES MONETÁRIOS

Timestamps técnicos (`created_at`, `updated_at`, `deleted_at`) em UTC. Datas de domínio preservam seu significado, sem conversão arbitrária.

Dinheiro: sempre `numeric`/`decimal` com precisão explícita no PostgreSQL. Nunca `float`/`double`. Formatar como `R$ 1.234,56` na UI.

## 8. ESTRUTURA SUPABASE

```
supabase/
  config.toml
  migrations/
    YYYYMMDDHHMMSS_descricao.sql
  functions/
  tests/
    database/
    rls/
```

Schema e policies versionados por migration SQL — nunca alteração manual no Dashboard sem migration equivalente. RLS habilitada explicitamente. Constraints para invariantes persistentes. Views/functions para leituras agregadas.

## 9. DOMÍNIO — VEÍCULOS

Herdado do Motora sem alterações de schema nesta migração inicial: `vehicles`, `maintenances`, `maintenance_items`, `refuelings`, `expenses` (despesas de veículo — não confundir com o domínio financeiro geral, ver seção 11), `reminders`, `attachments`, e as views `refueling_details`, `financial_entries`, `reminder_details`, `vehicle_dashboard`, `vehicle_timeline`. Ver migrations já aplicadas em `supabase/migrations/2026092*`.

Estrutura Flutter: `features/vehicles`, `features/maintenance`, `features/refueling`, `features/expenses`, `features/reminders`, `features/history`, `features/dashboard`, `features/attachments`.

## 10. DOMÍNIO — FINANÇAS

Portado e expandido do GranaFlow (.NET/`Usuario`/`Categoria`/`Pessoa`/`Transacao`), com schema redesenhado para UUID + RLS. Ainda não implementado neste repositório — especificação completa das tabelas, views e triggers em `ROADMAP.md` (M1).

Entidades: `categories`, `people`, `transactions` (com suporte a parcelamento via `installment_group_id`/`installment_index`/`installment_total`, e a vínculo automático com veículo via `source_type`/`source_id`), `budgets` (orçamento mensal por categoria), `recurring_transactions` (geração sob demanda ao abrir o app, nunca por cron), `savings_goals` + `goal_contributions`.

Views/functions agregadas: `finance_totals`, `finance_totals_by_category`, `finance_totals_by_person`, `finance_top_expenses`, `finance_top_income`, `budget_progress`, `finance_monthly_evolution` — todas `security_invoker`, para que nenhum client precise agregar dados de várias chamadas.

**Vínculo veículo → finanças (decidido)**: toda manutenção, abastecimento ou despesa de veículo gera automaticamente uma `transaction` correspondente via trigger no banco (`source_type`/`source_id` apontam pro registro de origem). Essa transação não é editável/excluível diretamente na tela de finanças — só refletindo o que acontece no registro de veículo, que é a fonte de verdade. RLS bloqueia `UPDATE`/`DELETE` direto quando `source_type is not null`.

Domínios cross-cutting adicionais: `vehicle_documents` (vencimento de seguro/licenciamento — alimenta a central de notificações), `trips` (diário de viagens), e a view `notification_items` (central de notificações unificada: lembretes + orçamento + recorrência + documentos).

## 11. IDENTIDADE VISUAL

Base herdada do Motora — dark-first, automotivo, minimalista:

- Background quase preto (`#0D0F12`), superfície `#171A1F`.
- Texto principal branco/off-white, secundário cinza.
- Accent verde elétrico (`#61E786`), usado com moderação (~5% da interface).
- Estados: verde (normal/sucesso), âmbar `#FFB547` (atenção), vermelho `#FF5D5D` (vencido/crítico).
- Cores de categoria financeira continuam definidas pelo usuário por categoria (herdado do GranaFlow), não fixas no design system.

Web (Next.js/Tailwind) deve espelhar os mesmos tokens — ver `mobile/lifeflow_app/lib/core/theme/app_colors.dart` como fonte de verdade até existir um arquivo de tokens compartilhado formal.

Evitar `CARD > CARD > CARD`. Usar espaço negativo, hierarquia e tipografia para separar conteúdo.

## 12. NAVEGAÇÃO E IDENTIDADE VISUAL — DECIDIDAS (protótipo aprovado)

Layout aprovado via protótipo de Design (canvas `LifeFlow — Protótipo Visual`). Referência obrigatória ao implementar M2–M5.

**Mobile** — bottom nav de 5 posições: Início, Finanças, **+** (quick-add central, elevado), Veículos, Mais. Quick-add abre bottom sheet único com duas seções (Veículo / Finanças). "Mais" contém perfil, Aparência, Categorias, Pessoas, Transações recorrentes, Sincronização, Exportar dados, Sair.

**Web** — sidebar fixa à esquerda (Início, Finanças, Veículos, Notificações, Mais) + conteúdo em grid responsivo. Mesma IA do mobile, layout adaptado à largura.

**Tema**: suporta `system` (padrão, segue o SO/navegador), `light` e `dark`, com troca manual — mas o controle de troca fica **dentro da aba Mais/Configurações** (seção "Aparência"), nunca solto no header de outras telas. Paleta clara e escura já definidas (ver protótipo): mesma identidade (Space Grotesk + Manrope, verde/âmbar/vermelho semânticos), cores recalculadas para contraste em cada modo — não é dark theme com opacidade invertida.

Home combinada: card de saldo (finanças) + card do veículo em destaque + próximo cuidado + orçamentos do mês — sem duplicar dashboards completos de cada módulo na home.

## 13. ROADMAP DE MIGRAÇÃO

Ver `ROADMAP.md` para a especificação completa e detalhada de cada milestone (tabelas, colunas, triggers, telas). Resumo:

1. **M1 — Schema de finanças**: `categories`, `people`, `transactions`, `budgets`, `recurring_transactions`, `savings_goals`, `vehicle_documents`, `trips`, views agregadas, trigger de sincronização veículo→transação, RLS e testes pgTAP.
2. **M2 — Finanças no Flutter**: `features/finance` completo (transações, orçamento, recorrência, metas, parcelamento), offline via Drift, telas de Configurações/Aparência, navegação final.
3. **M3 — Fundação do Next.js**: Supabase Auth, layout (sidebar), tema system/light/dark.
4. **M4 — Finanças no Web**: paridade com M2.
5. **M5 — Veículos no Web**: módulo novo, paridade com o Flutter (incluindo diário de viagens e documentos).
6. **M6 — Central de notificações + unificação de UX**: tela de notificações, revisão final de IA.
7. **M7 — Polimento e deploy**: Vercel (web), build mobile, rename de pacote (se decidido), decisão sobre repositórios antigos.

Não implementar milestones fora de ordem. Não antecipar funcionalidades de um milestone futuro dentro de um milestone atual.

## 14. TESTES

Supabase: priorizar testes de migrations, constraints, RLS, isolamento entre usuários, Database Functions e cálculos (consumo, custo, saldo, agregações financeiras).

Flutter: priorizar controllers/notifiers, regras de negócio, repositories, fluxos críticos.

Web: priorizar hooks/services de dados e componentes de formulário com regra de negócio (cálculo automático de valores, validação).

Não escrever testes inúteis apenas para aumentar coverage.

## 15. LOGS

Nunca logar senha, tokens completos, `service_role` ou informações sensíveis desnecessárias.

## 16. DEFINIÇÃO DE PRONTO

Uma tarefa só está concluída quando:

- código compila (Dart e/ou TypeScript conforme o escopo);
- `flutter analyze` / lint do Next.js passam sem issues;
- testes relevantes passam;
- migrations Supabase válidas e reproduzíveis a partir de banco vazio;
- RLS/policies habilitadas e testadas quando há tabela nova;
- UI possui loading/error/empty quando aplicável;
- nenhuma credencial foi commitada;
- README/AGENTS.md atualizados quando necessário.

## 17. PADRÕES PARA AGENTES

Antes de implementar qualquer tarefa:

1. Ler este documento.
2. Analisar o código existente e identificar padrões já usados (especialmente nas features de veículos, que são a referência madura do repositório).
3. Implementar somente o escopo do milestone solicitado.
4. Não alterar código não relacionado.
5. Não adicionar dependências sem necessidade.
6. Não criar abstrações especulativas para milestones futuros.
7. Executar build, testes e lint/analyze ao final.
8. Informar arquivos modificados, migrations criadas, decisões técnicas e riscos/pendências.

## 18. ESTADO REAL DO PROJETO

Este repositório foi criado do zero a partir da unificação de `Motora` (base) e `GranaFlow` (domínio financeiro portado). Estado atual:

- `mobile/lifeflow_app`: cópia integral de `Motora/mobile/motora_app`. Todas as features de veículos, auth, offline-first e testes existentes continuam funcionando como estavam no Motora. Pacote Dart renomeado para `lifeflow_app` no M7 (applicationId/bundle `br.com.lifeflow.app`, esquema de deep link `br.com.lifeflow`; o arquivo SQLite local continua `motora.sqlite` de propósito). M2 completo:
  - **Fase 1 (backend)**: `lib/features/finance/` com `domain/`, `data/` e `presentation/` para `Category`, `Person`, `Transaction` (parcelamento e transações espelhadas de veículo/recorrência), `Budget`, `RecurringTransaction` (+ geração sob demanda via RPC) e `SavingsGoal`/`GoalContribution`, mais `FinanceSummaryRepository` somente-leitura para as views agregadas do M1. `cached_records`/`pending_mutations` (Drift) já eram genéricos por `entityType`/`parentId`; não precisaram de migration nova, apenas duas correções em `core/sync/` para deixar de assumir `vehicle_id` como único campo de escopo (`OfflineRepositorySupport.readList` ganhou `parentIdField`; `SyncService._tableFor`/`_parentIdFor` passaram a reconhecer as novas entidades de finanças).
  - **Fase 2 (telas)**: Home combinada (saldo + veículo em destaque + próximo cuidado + orçamentos do mês), tela Finanças (saldo, orçamentos, meta em destaque, transações recentes), formulário de transação único/parcelado/recorrente, telas de metas (lista, formulário, detalhe com aportes), categorias/pessoas/recorrentes (dentro de "Mais"), tela "Mais" completa (perfil, Aparência, Categorias, Pessoas, Recorrentes, Sincronização, Exportar dados como placeholder desabilitado, Sair), quick-add unificado (Veículo + Finanças) e bottom nav de 5 posições (`core/navigation/`) usada por Início/Finanças/Veículos/Mais. Geração de ocorrências de recorrência disparada ao abrir a tela de Finanças (nunca por cron), conforme ROADMAP §1.5.
  - **Aparência (tema system/light/dark)**: como implementar de verdade exigia que todas as telas parassem de hardcodar `AppColors.*` e passassem a ler do `Theme`, foi feito um refactor completo para `AppPalette` (`ThemeExtension`) acessado via `context.colors` — cobre todas as telas pré-existentes de veículos também, não só as novas de finanças. Persistência via `shared_preferences` (nova dependência; preferida a uma tabela Drift nova para um valor único). Paleta clara (`AppColorsLight`) é uma escolha própria (contraste recalculado, mesma identidade), não veio do protótipo de design original — vale revisar visualmente contra o protótipo quando houver acesso a ele.
  - `flutter analyze` limpo e `flutter test` (35/35, incluindo os testes novos de controllers em `test/features/finance/`) passando. Não foi feito teste manual em emulador/dispositivo real (sem Supabase local configurado neste ambiente) — a validação ficou por `flutter analyze`/`flutter test`, incluindo um teste de widget que exercita login → Home → navegação pela tab "Mais" → sign-out de ponta a ponta.
- `supabase/`: schema de veículos (herdado do Motora) mais o schema de finanças do M1 (`categories`, `people`, `transactions`, `budgets`, `recurring_transactions`, `savings_goals`/`goal_contributions`, `vehicle_documents`, `trips`), views agregadas, trigger de sincronização veículo→transação e testes pgTAP — ver `supabase/migrations/2026092*` e `supabase/tests/`. Validado com `supabase db reset` + `supabase test db` (183 testes, 37 arquivos, todos passando, incluindo as suítes de veículos pré-existentes).
- `web/lifeflow_web`: M3 (fundação Next.js), M4 (Finanças no Web) e M5 (Veículos no Web) implementados.
  - **Stack real**: Next.js 16.3.6 (App Router, Turbopack), React 19, Tailwind v4, `shadcn/ui` (estilo `base-nova`, sobre `@base-ui/react` — não é mais Radix; API usa `render` em vez de `asChild`, `onClick` em vez de `onSelect` nos itens de menu). `@supabase/ssr`/`@supabase/supabase-js`, React Hook Form + Zod.
  - **Auth (3.1)**: login, cadastro, recuperação e troca de senha via Server Actions (`lib/auth/actions.ts`), mesmas regras de validação e mesmas mensagens de erro do mobile (`lib/auth/schemas.ts`, `lib/auth/errors.ts` espelham `auth_validators.dart`/`supabase_auth_repository.dart`). PKCE com confirmação por `app/auth/confirm/route.ts`. Sessão renovada a cada requisição por `proxy.ts` (nome novo do `middleware.ts` a partir do Next 16 — mesma função) chamando `lib/supabase/proxy.ts`, com redirect otimista (baseado em cookie) entre área pública/autenticada.
  - **Layout (3.2)**: `app/(auth)` (telas sem sidebar) e `app/(app)` (shell autenticado: sidebar fixa no desktop, bottom nav de 5 itens — Início/Finanças/Veículos/Notificações/Mais — em telas estreitas, mesma IA do protótipo). Não usa o componente `Sidebar` do shadcn (ele viraria um drawer no mobile, e o pedido era bottom nav); os primitivos instalados e não usados (`sidebar.tsx`, `sheet.tsx`, `tooltip.tsx`, `hooks/use-mobile.ts`) foram removidos.
  - **Tema (3.3)**: paleta clara/escura portada de `app_colors.dart`/`AppColorsLight` como CSS vars em `app/globals.css` (mesmos valores usados no Flutter); fontes trocadas para Space Grotesk (heading) + Manrope (body) via `next/font/google`. Alternância system/light/dark com `next-themes`, persistida em `localStorage`, tela "Aparência" em `/more/appearance` espelhando a do mobile.
  - **Camada de dados (3.4)**: `lib/supabase/client.ts` (browser) e `server.ts` (Server Components/Actions/Route Handlers) tipados sobre `Database`. `lib/supabase/database.types.ts` agora contém os **tipos reais**, gerados do banco local com `npx supabase gen types typescript --local` (Docker rodando + `supabase start`); regenerar sempre que houver migration nova (ou, contra produção, `--project-id ehjryjeiauocuomroset` após `supabase login`). `QueryProvider` (`@tanstack/react-query`) plugado no layout raiz; hooks por entidade vivem em `lib/finance/hooks.ts` (M4).
  - (Home combinada e Notificações foram implementadas no M6 — ver abaixo.)
  - **M4 — Finanças no Web** (paridade com o M2 do Flutter, direto no Supabase, sem API intermediária):
    - **Camada de dados**: `lib/finance/api.ts` (funções puras sobre o client tipado, erros já em pt-BR — mesmas mensagens do mobile), `hooks.ts` (React Query; toda escrita invalida `["finance"]`), `schemas.ts` (Zod), `format.ts` (moeda pt-BR, parse de valor, datas de domínio como string `YYYY-MM-DD` sem passar por `Date`/UTC), `options.ts`. Exclusões são soft delete (`deleted_at`), como no mobile; categorias/pessoas removidas continuam carregadas só para rotular transações antigas.
    - **Telas** (`app/(app)/finance/*`, sub-navegação por abas): Visão geral (saldo via `finance_totals`, orçamentos do mês via `budget_progress`, meta em destaque, transações recentes; dispara `generate_due_recurring_transactions` ao abrir — nunca cron), Transações (tabela com navegador de mês, busca, filtro de tipo/categoria, totais; linhas geradas por veículo/recorrência ficam com cadeado e sem editar/excluir), Orçamentos (CRUD por mês — o mobile só exibe; a tela de gestão é nova no web), Metas + detalhe com aportes. Em "Mais": `/more/categories`, `/more/people`, `/more/recurring`. Formulários em diálogo (React Hook Form + Zod), com modo Única/Parcelada/Recorrente no diálogo de transação.
    - **Decisões**: parcelamento faz um único `insert` em lote (atômico; o mobile insere uma a uma) e ao somar meses usa o último dia do mês de destino (31/01 + 1 mês = 28/02; o mobile transborda para março). Metas trazem os aportes por embed do PostgREST numa só chamada e o progresso é somado no client (não há view de progresso de meta). Vínculo aporte↔transação (`goal_contributions.transaction_id`) não é exposto na UI, igual ao mobile.
    - **Testes**: Vitest (`npm test`) cobre parse de valor, datas e parcelas (`lib/finance/format.test.ts`). Não há teste de componente ainda.
    - **Validação**: `npm run lint`, `npm run build`, `npm test` limpos. Exercitado ao vivo contra o Supabase **local** (usuário de teste, nunca produção): criar categoria, compra parcelada (3x com clamp de dia), exclusão, linhas travadas, geração de recorrência ao abrir, orçamento estourado (status crítico), aporte em meta. Dados de teste ficaram só no banco local.
  - **M5 — Veículos no Web** (paridade com o Flutter, mesmo padrão de `lib/finance/`, direto no Supabase):
    - **Camada de dados**: `lib/vehicles/api.ts` (funções puras sobre o client tipado, erros em pt-BR, mesmas mensagens do mobile; regras do banco sem código próprio — data futura, hodômetro — traduzidas por texto da exceção), `hooks.ts` (React Query; toda escrita invalida `["vehicles"]` **e** `["finance"]`, pois manutenção/abastecimento/despesa geram transação por trigger), `schemas.ts` (Zod, espelha as constraints do banco e as regras do RPC `save_maintenance`), `format.ts` (km, litros, placa, cálculo litros×preço=total, datas/horas), `options.ts` (rótulos dos enums). IDs de manutenção/abastecimento/despesa/lembrete/anexo são UUIDs gerados no client (`crypto.randomUUID()`); veículo, documento e viagem usam o default do banco. Exclusões são soft delete (`deleted_at`).
    - **Telas** (`app/(app)/vehicles/*`): lista de veículos (cards com gasto do mês e nº de cuidados via `vehicle_dashboard`); shell `vehicles/[id]` com sub-navegação por abas: Visão geral (gasto do mês, consumo, custo/km, distância, próximo cuidado, documentos a vencer, ações rápidas), Histórico (`vehicle_timeline` paginada de 30 em 30, agrupada por mês), Manutenções (itens via `save_maintenance`; detalhe com **anexos** no bucket `vehicle-attachments` — JPG/PNG/PDF até 10 MB, URL assinada de 5 min), Abastecimentos (consumo via `refueling_details`), Despesas, Lembretes (`reminder_details`, concluir/reabrir), Documentos (só metadados de vencimento) e Viagens (diário: iniciar/encerrar/editar). Ao criar uma manutenção com "próxima troca", oferece criar os lembretes (igual ao mobile). O catálogo FIPE (marca/modelo) é só sugestão via `<datalist>`; se a API falhar ou estiver limitada, os campos seguem livres.
    - **Decisões**: o diário de viagens **não existe no Flutter** (só o schema do M1); a UI web é desenho próprio — iniciar (hodômetro inicial pré-preenchido com o do veículo), encerrar (km e horário de chegada) e editar; o hodômetro do veículo avança por trigger do banco ao encerrar. Foto do veículo não implementada (`photo_path` está reservado no schema, sem Storage ainda — mesmo estado do mobile). Documentos e viagens usam soft delete, embora a policy também permita `DELETE`.
    - **Testes**: `lib/vehicles/vehicles.test.ts` (parsing, placa, recálculo de abastecimento, validações Zod de veículo/manutenção/abastecimento/lembrete/viagem). `vitest.config.ts` ganhou o alias `@` (igual ao tsconfig) para testes que importam módulos com `@/`.
    - **Validação**: `npm run lint`, `npm run build`, `npm test` (24 testes) limpos. Exercitado ao vivo contra o Supabase **local** (nunca produção): cadastro com validação e placa duplicada, 2 abastecimentos (recálculo do total; consumo 16,67 km/l no dashboard), manutenção com oferta de lembrete, despesa, documento vencendo em 10 dias, viagem iniciar→encerrar (hodômetro avançou), upload/abrir/excluir anexo (RLS do Storage ok), timeline, transações espelho aparecendo em Finanças e remoção de veículo. Não verificado visualmente (janela do browser oculta na sessão, sem screenshots): layout responsivo e tema claro/escuro só por leitura de código e DOM.
  - **Validado ao vivo** contra o Supabase de produção do projeto (`ehjryjeiauocuomroset`): cadastro real cria usuário e dispara e-mail de confirmação (visto via mailinator.com), proxy redireciona corretamente para `/login` quando não autenticado. O passo final (abrir o link de confirmação → sessão → sidebar → sign out) não foi possível de exercitar dentro do ambiente de browser desta sessão (bloqueio de navegação para o domínio do Supabase); ficou descrito para o usuário testar por conta própria. `npm run lint` e `npm run build` limpos.
  - **Pendências**: Node local é 20.12 e tanto `@supabase/supabase-js` quanto o `shadcn` CLI já pedem Node ≥22 (funciona por enquanto, mas vale atualizar); existe uma conta de teste (`teste.lifeflow.web@mailinator.com`) no Supabase de produção que pode ser removida em Authentication → Users.
  - **M6 — Central de notificações + unificação de UX**:
    - **Banco**: migration `20260923100000_notification_items_vehicle_id.sql` acrescenta `vehicle_id` (só lembretes e documentos; nulo nos demais) à view `notification_items` para deep link até o veículo. pgTAP: 185 testes passando após `db reset`.
    - **Web**: `lib/notifications/` (`model.ts` — ordenação por gravidade/vencimento e rota de destino; `api.ts`; `hooks.ts`), tela `/notifications`, badge de contagem na sidebar e na bottom nav (cor pela pior severidade). A query vive sob a raiz `["finance"]`, então qualquer escrita de finanças/veículos atualiza central e badge sem mexer nos hooks de mutação. Home combinada (`components/home/home-screen.tsx`): saldo, veículo em destaque (seletor se houver mais de um), próximo cuidado e orçamentos do mês. `placeholder-card.tsx` removido (sem uso).
    - **Mobile**: `features/notifications/` (domínio, repositório Supabase com cache offline, controller, `NotificationsPage`, `NotificationBell` com badge), rota `/notifications`, sino nas AppBars de Início/Finanças/Veículos/Mais. Documento de veículo leva ao veículo (o app não tem tela de documentos).
    - **Revisão de IA / inconsistências corrigidas**: wordmark e títulos do mobile ainda diziam "MOTORA" (Início, Veículos, auth, splash, título do app) → "LIFEFLOW"/"LifeFlow". Diferença assumida: no mobile Notificações é o sino do header (a bottom nav tem os 5 slots já ocupados: Início, Finanças, +, Veículos, Mais); no web é item da sidebar/bottom nav. Recorrência pendente leva a Finanças (a geração ocorre ao abrir a visão geral).
    - **Testes**: web `lib/notifications/notifications.test.ts` (30 testes no total); mobile `test/features/notifications/` (41 no total). `npm run lint`, `npm run build`, `npm test`, `flutter analyze`, `flutter test` limpos.
    - **Não verificado**: web ao vivo contra o Supabase local (o `.env.local` aponta para produção e não foi trocado) e mobile em emulador; layout, badge e Home só validados por build/tipos/testes. Ambiente: o disco C: ficou quase cheio e derrubou um `flutter test`; rodar com `TEMP` em outro disco resolve.
- `docs/offline-first.md`: estratégia offline-first herdada do Motora, válida também para o domínio de finanças no mobile (ver M2 Fase 1 acima).

M1–M6 implementados — ver `ROADMAP.md`. M7 em andamento:
- **Logo aplicada** (`design/logo/`): ícones Android (legacy + adaptive), iOS, favicon/apple-icon web (`app/icon.svg`), `Wordmark`/`LogoMark` no web (`components/brand/logo.tsx`) e `LifeFlowWordmark`/`LifeFlowMark` no Flutter (`assets/logo/*.png` brancos, tingidos pelo tema).
- **Produção migrada**: as migrations de finanças (M1, `20260922*` e `20260923100000`) só foram aplicadas no Supabase de produção (`ehjryjeiauocuomroset`) em 2026-09-23, via `supabase link` + `db push`; antes disso, as telas de finanças falhavam em produção (tabelas inexistentes). Migration nova precisa de `db push` antes de testar contra produção.
- **Feito**: rename `motora_app` → `lifeflow_app` (imports, classe `LifeFlowApp`, Android/iOS ids, labels, `supabase/config.toml` redirect); assinatura release Android via `android/key.properties` (fallback debug); `web/lifeflow_web/.env.example`; runbook de deploy no README. Web: `lint`, `test` (30) e `build` limpos.
- **Não verificado**: `flutter analyze`/`test`/build do rename — Flutter não está no PATH desta máquina.
- **Pendente (ações do usuário)**: deploy Vercel + URLs de redirect no Supabase (o deep link mudou: atualizar também no painel de produção); gerar keystore e APK assinado; arquivar Motora/granaflowapp/GranaFlowAPI (decidido: arquivar, com README apontando para o LifeFlow); `ios` não testado; `ios/Runner.xcodeproj` mudou de bundle id.
