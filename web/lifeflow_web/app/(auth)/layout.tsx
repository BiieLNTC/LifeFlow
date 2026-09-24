import { LogoMark } from "@/components/brand/logo";
export default function AuthLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="flex flex-1 items-center justify-center bg-background px-4 py-12">
      <div className="w-full max-w-sm">
        <div className="mb-8 flex flex-col items-center gap-1">
          <LogoMark className="size-16 text-primary" />
        </div>
        {children}
      </div>
    </div>
  );
}
