import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";
import type { Database } from "@/lib/supabase/database.types";
import { supabasePublishableKey, supabaseUrl } from "@/lib/supabase/env";

const PUBLIC_ROUTES = new Set(["/login", "/sign-up", "/forgot-password"]);

/**
 * Renova a sessão Supabase a cada requisição e faz o redirect otimista
 * (baseado no cookie, sem bater no banco) entre área pública/autenticada.
 * Chamado por `proxy.ts` na raiz — nome novo do antigo `middleware.ts`
 * a partir do Next.js 16 (mesma função, ver node_modules/next/dist/docs).
 */
export async function updateSession(request: NextRequest) {
  let response = NextResponse.next({ request });

  const supabase = createServerClient<Database>(
    supabaseUrl,
    supabasePublishableKey,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll();
        },
        setAll(cookiesToSet) {
          for (const { name, value } of cookiesToSet) {
            request.cookies.set(name, value);
          }
          response = NextResponse.next({ request });
          for (const { name, value, options } of cookiesToSet) {
            response.cookies.set(name, value, options);
          }
        },
      },
    },
  );

  const {
    data: { user },
  } = await supabase.auth.getUser();

  const path = request.nextUrl.pathname;
  const isPublicRoute = PUBLIC_ROUTES.has(path);
  const isUpdatePasswordRoute = path === "/update-password";

  if (!user && !isPublicRoute && !isUpdatePasswordRoute) {
    const url = request.nextUrl.clone();
    url.pathname = "/login";
    return NextResponse.redirect(url);
  }

  if (user && isPublicRoute) {
    const url = request.nextUrl.clone();
    url.pathname = "/";
    return NextResponse.redirect(url);
  }

  return response;
}
