import { MaintenancesScreen } from "@/components/vehicles/maintenances-screen";

export default async function Page({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  return <MaintenancesScreen vehicleId={id} />;
}
