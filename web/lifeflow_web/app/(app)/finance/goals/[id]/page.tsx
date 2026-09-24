import { GoalDetailScreen } from "@/components/finance/goal-detail-screen";

export default async function GoalDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  return <GoalDetailScreen goalId={id} />;
}
