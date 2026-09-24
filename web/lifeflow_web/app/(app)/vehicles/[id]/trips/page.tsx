import { TripsScreen } from "@/components/vehicles/trips-screen";

export default async function Page({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  return <TripsScreen vehicleId={id} />;
}
