import { redirect } from "next/navigation";
import { AppSidebar } from "@/components/app-sidebar";
import { MobileBottomNav } from "@/components/mobile-bottom-nav";
import { createClient } from "@/lib/supabase/server";

export default async function AppLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) redirect("/login");

  const name = (user.user_metadata?.name as string | undefined)?.trim();
  const userLabel = name || user.email?.split("@")[0] || "você";

  return (
    <div className="flex min-h-screen flex-1">
      <AppSidebar
        className="hidden lg:flex"
        userLabel={userLabel}
        userEmail={user.email ?? null}
      />
      <div className="flex flex-1 flex-col">
        <main className="flex-1 px-4 pb-24 pt-6 lg:px-10 lg:pb-10 lg:pt-8">
          {children}
        </main>
        <MobileBottomNav className="lg:hidden" />
      </div>
    </div>
  );
}
