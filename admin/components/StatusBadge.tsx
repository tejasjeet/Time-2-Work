import { titleCase } from "@/lib/format";

const TONE: Record<string, string> = {
  active: "bg-emerald-50 text-emerald-800 ring-emerald-200",
  open: "bg-emerald-50 text-emerald-800 ring-emerald-200",
  success: "bg-emerald-50 text-emerald-800 ring-emerald-200",
  paid: "bg-emerald-50 text-emerald-800 ring-emerald-200",
  completed: "bg-emerald-50 text-emerald-800 ring-emerald-200",
  resolved: "bg-emerald-50 text-emerald-800 ring-emerald-200",
  verified: "bg-sky-50 text-sky-800 ring-sky-200",
  worker: "bg-sky-50 text-sky-800 ring-sky-200",
  business: "bg-indigo-50 text-indigo-800 ring-indigo-200",
  admin: "bg-zinc-900 text-white ring-zinc-900",
  pending: "bg-amber-50 text-amber-800 ring-amber-200",
  pending_payment: "bg-amber-50 text-amber-800 ring-amber-200",
  reviewed: "bg-amber-50 text-amber-800 ring-amber-200",
  suspended: "bg-amber-50 text-amber-800 ring-amber-200",
  started: "bg-amber-50 text-amber-800 ring-amber-200",
  accepted: "bg-amber-50 text-amber-800 ring-amber-200",
  in_progress: "bg-amber-50 text-amber-800 ring-amber-200",
  posting_fee: "bg-amber-50 text-amber-800 ring-amber-200",
  job_fee: "bg-amber-50 text-amber-800 ring-amber-200",
  job_payout: "bg-indigo-50 text-indigo-800 ring-indigo-200",
  payout: "bg-indigo-50 text-indigo-800 ring-indigo-200",
  created: "bg-zinc-100 text-zinc-700 ring-zinc-200",
  blocked: "bg-red-50 text-red-800 ring-red-200",
  cancelled: "bg-red-50 text-red-800 ring-red-200",
  failed: "bg-red-50 text-red-800 ring-red-200",
  reported: "bg-red-50 text-red-800 ring-red-200",
  dismissed: "bg-zinc-100 text-zinc-600 ring-zinc-200",
  inactive: "bg-zinc-100 text-zinc-600 ring-zinc-200",
  refunded: "bg-zinc-100 text-zinc-700 ring-zinc-200",
  refund: "bg-zinc-100 text-zinc-700 ring-zinc-200",
  draft: "bg-zinc-100 text-zinc-600 ring-zinc-200",
  removed: "bg-zinc-100 text-zinc-600 ring-zinc-200",
  commission: "bg-zinc-900 text-white ring-zinc-900",
};

export function StatusBadge({ value, className = "" }: { value: string; className?: string }) {
  const key = (value || "unknown").toLowerCase();
  const tone = TONE[key] ?? "bg-zinc-100 text-zinc-700 ring-zinc-200";
  return (
    <span className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ring-1 ring-inset ${tone} ${className}`}>
      {titleCase(value || "unknown")}
    </span>
  );
}
