# Estratégia offline-first

O banco local Drift/SQLite mantém um cache por usuário e uma fila durável de mutações. Veículos, manutenções, abastecimentos, despesas e lembretes podem ser criados, alterados e excluídos sem conexão. Dashboard e timeline usam o último snapshot disponível. Anexos continuam online-only porque o envio seguro de binários exige uma fila própria, fora do escopo deste milestone.

## Estados locais

- `synced`: igual ao servidor;
- `pending_create`: criação aguardando envio;
- `pending_update`: alteração aguardando envio;
- `pending_delete`: exclusão lógica aguardando envio;
- `failed`: rejeitado pelo servidor ou em conflito, com dados locais preservados.

O aplicativo tenta sincronizar ao iniciar uma sessão, ao voltar ao primeiro plano e quando o usuário toca no aviso de sincronização. Falhas de conectividade mantêm a operação pendente. Rejeições permanentes ficam como `failed` e são apresentadas ao usuário.

## Conflitos

Ao editar ou excluir um registro sincronizado, a fila guarda o `updated_at` que serviu de base para a alteração. Antes de enviar, compara essa versão com a versão atual do Supabase.

Se forem diferentes, o Motora não aplica *last write wins*: marca a mutação como `failed`, preserva o payload local e informa que o item precisa de revisão. Uma tentativa manual repete a verificação; uma futura interface de resolução poderá permitir comparar e escolher os dados sem mudar essa regra de segurança.

Criações usam UUID gerado no dispositivo e `upsert`, permitindo reenvio idempotente. Exclusões usam `deleted_at`, mantendo a semântica de soft delete necessária para sincronização.
