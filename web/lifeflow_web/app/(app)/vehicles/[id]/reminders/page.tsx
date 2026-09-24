import { RemindersScreen } from "@/components/vehicles/reminders-screen";

export default async function Page({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  return <RemindersScreen vehicleId={id} />;
}
