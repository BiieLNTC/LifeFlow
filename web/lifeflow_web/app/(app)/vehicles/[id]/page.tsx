import { OverviewScreen } from "@/components/vehicles/overview-screen";

export default async function Page({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  return <OverviewScreen vehicleId={id} />;
}
