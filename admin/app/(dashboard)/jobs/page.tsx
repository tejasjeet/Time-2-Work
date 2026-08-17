"use client";

import { useMemo, useState } from "react";
import { ConfirmDialog } from "@/components/ConfirmDialog";
import { DataTable } from "@/components/DataTable";
import { ErrorBanner } from "@/components/ErrorBanner";
import { PageHeader } from "@/components/PageHeader";
import { StatusBadge } from "@/components/StatusBadge";
import { useToast } from "@/components/Toast";
import { FilterChip, SearchInput } from "@/components/Toolbar";
import { adminApi } from "@/lib/api";
import { formatDate, formatINR } from "@/lib/format";
import type { Job } from "@/lib/types";
import { useAsync } from "@/lib/useAsync";
import { useDebouncedValue } from "@/lib/useDebouncedValue";

const FILTERS = [
  { value: "", label: "All" },
  { value: "reported", label: "Reported" },
  { value: "completed", label: "Completed" },
  { value: "open", label: "Open" },
  { value: "in_progress", label: "In progress" },
];

export default function JobsPage() {
  const toast = useToast();
  const [search, setSearch] = useState("");
  const [filter, setFilter] = useState("");
  const [remove, setRemove] = useState<Job | null>(null);
  const [busy, setBusy] = useState(false);

  const debouncedSearch = useDebouncedValue(search);
  const query = useMemo(() => {
    const q: Record<string, string> = {};
    if (debouncedSearch.trim()) q.search = debouncedSearch.trim();
    if (filter === "reported") q.reported = "true";
    else if (filter) q.status = filter;
    return q;
  }, [debouncedSearch, filter]);

  const { data, loading, error, reload } = useAsync(() => adminApi.jobs(query), [query.search, query.status, query.reported]);
  const reports = useAsync(() => adminApi.reports(), []);
  const reportedIds = new Set((reports.data?.items ?? []).filter((r) => r.targetType === "job").map((r) => r.target));

  const rows = (data?.items ?? [])
    .map((job) => ({ ...job, reported: job.reported || reportedIds.has(job.id) }))
    .filter((job) => {
      if (filter === "reported") return job.reported;
      if (filter) return job.status === filter;
      if (debouncedSearch.trim()) {
        const q = debouncedSearch.trim().toLowerCase();
        return [job.title, job.poster, job.location, job.category].some((value) => value.toLowerCase().includes(q));
      }
      return true;
    });

  async function onDelete() {
    if (!remove) return;
    setBusy(true);
    try {
      await adminApi.deleteJob(remove.id);
      toast("Job removed");
      setRemove(null);
      await reload();
    } catch (err) {
      toast(err instanceof Error ? err.message : "Could not remove job", "err");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div>
      <PageHeader title="Jobs" description="Review listings, focus on reported or completed work, and remove listings." />
      {error ? <ErrorBanner message={error} onRetry={reload} /> : null}

      <div className="mb-4 flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
        <SearchInput value={search} onChange={setSearch} placeholder="Search title, poster, or city" />
        <div className="flex flex-wrap gap-2">
          {FILTERS.map((item) => (
            <FilterChip key={item.value} active={filter === item.value} onClick={() => setFilter(item.value)}>
              {item.label}
            </FilterChip>
          ))}
        </div>
      </div>

      <DataTable
        loading={loading}
        rows={rows}
        emptyTitle="No jobs found"
        emptyHint="Adjust filters or wait for new posts."
        columns={[
          { key: "title", header: "Job", render: (j) => (
            <div>
              <p className="font-medium">{j.title}</p>
              <p className="text-xs text-ink-500">{j.category || "Uncategorized"}</p>
            </div>
          ) },
          { key: "poster", header: "Poster", render: (j) => j.poster },
          { key: "pay", header: "Pay", render: (j) => formatINR(j.pay) },
          { key: "status", header: "Status", render: (j) => (
            <div className="flex flex-wrap gap-1">
              <StatusBadge value={j.status} />
              {j.reported ? <StatusBadge value="reported" /> : null}
            </div>
          ) },
          { key: "location", header: "Location", render: (j) => j.location || "—" },
          { key: "workersRequired", header: "Slots", render: (j) => String(j.workersRequired) },
          { key: "createdAt", header: "Posted", render: (j) => formatDate(j.createdAt) },
          { key: "actions", header: "", className: "text-right", render: (j) => (
            <button type="button" className="btn-ghost text-red-600 hover:bg-red-50" onClick={() => setRemove(j)}>
              Remove
            </button>
          ) },
        ]}
      />

      <ConfirmDialog
        open={Boolean(remove)}
        title="Remove job"
        message={remove ? `Permanently remove “${remove.title}”? This cannot be undone from the admin panel.` : ""}
        confirmLabel="Remove"
        danger
        busy={busy}
        onClose={() => setRemove(null)}
        onConfirm={() => void onDelete()}
      />
    </div>
  );
}
