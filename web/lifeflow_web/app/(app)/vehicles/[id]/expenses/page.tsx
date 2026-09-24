import { ExpensesScreen } from "@/components/vehicles/expenses-screen";

export default async function Page({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  return <ExpensesScreen vehicleId={id} />;
}
