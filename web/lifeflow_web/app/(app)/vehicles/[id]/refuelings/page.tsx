import { RefuelingsScreen } from "@/components/vehicles/refuelings-screen";

export default async function Page({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  return <RefuelingsScreen vehicleId={id} />;
}
