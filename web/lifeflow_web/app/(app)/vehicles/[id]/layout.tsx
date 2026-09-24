import { VehicleShell } from "@/components/vehicles/vehicle-shell";

export default async function VehicleLayout({
  children,
  params,
}: {
  children: React.ReactNode;
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  return <VehicleShell vehicleId={id}>{children}</VehicleShell>;
}
