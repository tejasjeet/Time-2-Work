export function Spinner({ label = "Loading" }: { label?: string }) {
  return (
    <div className="flex items-center justify-center gap-3 py-16 text-sm text-ink-500" role="status">
      <span className="h-5 w-5 animate-spin rounded-full border-2 border-ink-200 border-t-amber-500" />
      {label}…
    </div>
  );
}
