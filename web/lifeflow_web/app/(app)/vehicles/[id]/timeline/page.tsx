import { TimelineScreen } from "@/components/vehicles/timeline-screen";

export default async function Page({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  return <TimelineScreen vehicleId={id} />;
}
