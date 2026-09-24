# LifeFlow

Controle financeiro e gestão de veículos, num produto só.

LifeFlow nasce da unificação de dois produtos anteriores:

- **Motora** (gestão de veículos — quilometragem, manutenções, abastecimentos, despesas, lembretes) — base arquitetural deste repositório.
- **GranaFlow** (controle financeiro pessoal — transações, categorias, pessoas) — domínio sendo portado para o schema Supabase unificado.

Este repositório contém:

- `mobile/lifeflow_app/`: aplicativo Flutter para Android e iOS (cópia da base do Motora, em processo de expansão com o módulo de finanças).
- `web/lifeflow_web/`: aplicativo Next.js para web, consumindo o mesmo backend Supabase diretamente (sem API intermediária).
- `supabase/`: configuração local, migrations SQL e testes de banco — fonte única de verdade do schema, compartilhada por mobile e web.
- `docs/`: documentação de arquitetura (estratégia offline-first, etc).

Consulte [`AGENTS.md`](./AGENTS.md) para a especificação completa do produto, arquitetura, padrões de código e estado atual da migração.

## Status da migração

- [x] M1–M6: schema de finanças, Flutter (finanças), fundação web, finanças e veículos no web, central de notificações.
- [~] M7 — polimento e deploy: rename do pacote feito (`lifeflow_app`, applicationId/bundle `br.com.lifeflow.app`, deep link `br.com.lifeflow://auth-callback`); assinatura release Android configurada; falta executar o deploy na Vercel, gerar o APK assinado e arquivar os repositórios antigos (ver "Deploy").

## Supabase

Requisitos: Node.js 20+, Docker e Supabase CLI instalada como dependência do projeto.

```powershell
cd supabase
npm install
npm run supabase:start
```

O schema deve ser alterado somente por migrations versionadas. Tabelas expostas ao cliente devem ter grants mínimos e RLS com policies explícitas — ver `AGENTS.md`.

## Mobile

Requisitos: Flutter stable e toolchains Android/iOS.

```powershell
cd mobile/lifeflow_app
flutter pub get
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...
```

## Web

Requisitos: Node.js 20+.

```powershell
cd web/lifeflow_web
npm install
npm run dev
```

Variáveis de ambiente (`.env.local`):

```
NEXT_PUBLIC_SUPABASE_URL=...
NEXT_PUBLIC_SUPABASE_ANON_KEY=...
```

## Deploy

**Web (Vercel)**: importar o repositório, Root Directory `web/lifeflow_web`. Variáveis: `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`, `NEXT_PUBLIC_SITE_URL` (ver `.env.example`). Depois, no Supabase (Authentication → URL Configuration), definir Site URL como a URL do deploy e adicionar `<url>/auth/confirm` e `br.com.lifeflow://auth-callback` em Redirect URLs. Nunca usar a `service_role`.

**Android**: criar o keystore (`keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`), copiar `android/key.properties.example` para `android/key.properties` (ignorado pelo git) e rodar `flutter build apk --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...` (ou `appbundle`). Guarde o keystore fora do repositório: perdê-lo impede atualizar o app publicado.
