import { cn } from "@/lib/utils";

/** Wordmark LIFEFLOW (traço desenhado, herda a cor via currentColor). */
export function Wordmark({ className }: { className?: string }) {
  return (
    <svg
      viewBox="-20 -20 764 140"
      role="img"
      aria-label="LifeFlow"
      className={cn("h-4 w-auto", className)}
    >
      <g fill="none" stroke="currentColor" stroke-width="14" stroke-linecap="round" stroke-linejoin="round">
<path d="M0 0V100H56"/>
<path transform="translate(90)" d="M0 0V100"/>
<path transform="translate(124)" d="M0 100V40C0 14 16 0 40 0H52M0 50H44"/>
<path transform="translate(210)" d="M56 0H0V100H56M0 50H44"/>
<path transform="translate(300)" d="M0 100V40C0 14 16 0 40 0H52M0 50H44"/>
<path transform="translate(386)" d="M0 0V100H56"/>
<rect x="476" y="0" width="84" height="100" rx="42"/>
<path transform="translate(594)" d="M0 0L28 100L55 30L82 100L110 0"/></g>
    </svg>
  );
}

/** Símbolo LF (herda a cor via currentColor). */
export function LogoMark({ className }: { className?: string }) {
  return (
    <svg
      viewBox="0 0 512 512"
      role="img"
      aria-label="LifeFlow"
      className={cn("size-10", className)}
    >
      <g transform="translate(256 256) scale(.78) translate(-256 -256) translate(30 0)" fill="none" stroke="currentColor" stroke-width="40" stroke-linecap="round" stroke-linejoin="round"><path d="M150 112 V392 H262" /><path d="M262 392 V196 C262 142 296 112 352 112 H372" /><path d="M262 250 H346" /></g>
    </svg>
  );
}
