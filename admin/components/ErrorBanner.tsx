import { IconAlert } from "./icons";

export function ErrorBanner({ message, onRetry }: { message: string; onRetry?: () => void }) {
  return (
    <div className="mb-5 flex items-start gap-3 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800">
      <IconAlert className="mt-0.5 h-4 w-4 shrink-0" />
      <div className="flex-1">
        <p className="font-medium">Could not load data</p>
        <p className="mt-0.5 text-red-700">{message}</p>
        <p className="mt-1 text-xs text-red-600">Confirm the API is running at {process.env.NEXT_PUBLIC_API_URL || "http://localhost:4000/api"}.</p>
      </div>
      {onRetry ? (
        <button type="button" onClick={onRetry} className="btn-secondary !border-red-200 !bg-white !px-3 !py-1.5 text-xs">
          Retry
        </button>
      ) : null}
    </div>
  );
}
