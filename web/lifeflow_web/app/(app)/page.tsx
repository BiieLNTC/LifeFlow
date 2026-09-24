import { HomeScreen } from "@/components/home/home-screen";
import { createClient } from "@/lib/supabase/server";

export default async function HomePage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  const name = (user?.user_metadata?.name as string | undefined)?.trim();
  const greeting = name || user?.email?.split("@")[0] || "você";

  return <HomeScreen greeting={greeting} />;
}
