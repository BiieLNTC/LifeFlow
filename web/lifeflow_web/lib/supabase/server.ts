import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";
import type { Database } from "@/lib/supabase/database.types";
import { supabasePublishableKey, supabaseUrl } from "@/lib/supabase/env";

/**
 * Client Supabase para Server Components, Server Actions e Route Handlers.
 * `setAll` pode falhar quando chamado de um Server Component puro (sem
 * como escrever cookies) — é seguro ignorar nesse caso, porque a sessão já
 * foi renovada pelo proxy (ver proxy.ts) antes da requisição chegar aqui.
 */
export async function createClient() {
  const cookieStore = await cookies();

  return createServerClient<Database>(supabaseUrl, supabasePublishableKey, {
    cookies: {
      getAll() {
        return cookieStore.getAll();
      },
      setAll(cookiesToSet) {
        try {
          for (const { name, value, options } of cookiesToSet) {
            cookieStore.set(name, value, options);
          }
        } catch {
          // Chamado de um Server Component — ignorado, ver comentário acima.
        }
      },
    },
  });
}
