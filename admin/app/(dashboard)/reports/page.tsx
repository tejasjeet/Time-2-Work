"use client";

import { useMemo, useState } from "react";
import { DataTable } from "@/components/DataTable";
import { ErrorBanner } from "@/components/ErrorBanner";
import { PageHeader } from "@/components/PageHeader";
import { StatusBadge } from "@/components/StatusBadge";
import { useToast } from "@/components/Toast";
import { FilterChip } from "@/components/Toolbar";
import { adminApi } from "@/lib/api";
import { formatDateTime } from "@/lib/format";
import type { Report } from "@/lib/types";
import { useAsync } from "@/lib/useAsync";

const FILTERS = [
  { value: "", label: "All" },
  { value: "open", label: "Open" },
  { value: "reviewed", label: "Reviewed" },
  { value: "resolved", label: "Resolved" },
  { value: "dismissed", label: "Dismissed" },
];

export default function ReportsPage() {
  const toast = useToast();
  const [status, setStatus] = useState("");
  const [busyId, setBusyId] = useState<string | null>(null);
  const query = useMemo(() => ({ status: status || undefined }), [status]);
  const { data, loading, error, reload } = useAsync(() => adminApi.reports(query), [query.status]);

  const rows = (data?.items ?? []).filter((row) => (status ? row.status === status : true));

  async function update(report: Report, next: string) {
    setBusyId(report.id);
    try {
      await adminApi.updateReport(report.id, { status: next });
      toast(`Report ${next}`);
      await reload();
    } catch (err) {
      toast(err instanceof Error ? err.message : "Update failed", "err");
    } finally {
      setBusyId(null);
    }
  }

  return (
    <div>
      <PageHeader title="Reports" description="Complaints against users or jobs. Review, resolve, or dismiss." />
      {error ? <ErrorBanner message={error} onRetry={reload} /> : null}

      <div className="mb-4 flex flex-wrap gap-2">
        {FILTERS.map((item) => (
          <FilterChip key={item.value} active={status === item.value} onClick={() => setStatus(item.value)}>
            {item.label}
          </FilterChip>
        ))}
      </div>

      <DataTable
        loading={loading}
        rows={rows}
        emptyTitle="No complaints"
        emptyHint="Reported users and jobs will appear here."
        columns={[
          { key: "target", header: "Target", render: (r) => (
            <div>
              <p className="font-medium">{r.target}</p>
              <p className="text-xs text-ink-500">{r.targetType}</p>
            </div>
          ) },
          { key: "reporter", header: "Reporter", render: (r) => r.reporter },
          { key: "reason", header: "Reason", className: "max-w-xs", render: (r) => <span className="line-clamp-2">{r.reason}</span> },
          { key: "status", header: "Status", render: (r) => <StatusBadge value={r.status} /> },
          { key: "createdAt", header: "Filed", render: (r) => formatDateTime(r.createdAt) },
          { key: "actions", header: "", className: "text-right", render: (r) => (
            <div className="flex justify-end gap-1">
              {r.status === "open" || r.status === "pending" ? (
                <button type="button" className="btn-ghost" disabled={busyId === r.id} onClick={() => update(r, "reviewed")}>
                  Review
                </button>
              ) : null}
              {r.status !== "resolved" ? (
                <button type="button" className="btn-ghost" disabled={busyId === r.id} onClick={() => update(r, "resolved")}>
                  Resolve
                </button>
              ) : null}
              {r.status !== "dismissed" ? (
                <button type="button" className="btn-ghost text-ink-500" disabled={busyId === r.id} onClick={() => update(r, "dismissed")}>
                  Dismiss
                </button>
              ) : null}
            </div>
          ) },
        ]}
      />
    </div>
  );
}
