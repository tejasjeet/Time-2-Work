"use client";

import { useMemo, useState } from "react";
import { DataTable } from "@/components/DataTable";
import { ErrorBanner } from "@/components/ErrorBanner";
import { PageHeader } from "@/components/PageHeader";
import { StatusBadge } from "@/components/StatusBadge";
import { FilterChip, SearchInput } from "@/components/Toolbar";
import { adminApi } from "@/lib/api";
import { formatDateTime, formatINR } from "@/lib/format";
import { useAsync } from "@/lib/useAsync";
import { useDebouncedValue } from "@/lib/useDebouncedValue";

const TYPE_FILTERS = [
  { value: "", label: "All types" },
  { value: "job_fee", label: "Posting fees" },
  { value: "job_payout", label: "Payouts" },
  { value: "refund", label: "Refunds" },
  { value: "commission", label: "Commission" },
];

const STATUS_FILTERS = [
  { value: "", label: "All statuses" },
  { value: "paid", label: "Paid" },
  { value: "completed", label: "Completed" },
  { value: "created", label: "Created" },
  { value: "pending", label: "Pending" },
  { value: "failed", label: "Failed" },
  { value: "refunded", label: "Refunded" },
];

export default function PaymentsPage() {
  const [search, setSearch] = useState("");
  const [type, setType] = useState("");
  const [status, setStatus] = useState("");

  const debouncedSearch = useDebouncedValue(search);
  const query = useMemo(
    () => ({
      search: debouncedSearch.trim() || undefined,
      type: type || undefined,
      status: status || undefined,
    }),
    [debouncedSearch, type, status],
  );

  const { data, loading, error, reload } = useAsync(() => adminApi.payments(query), [query.search, query.type, query.status]);

  const rows = (data?.items ?? []).filter((row) => {
    if (type && !row.type.includes(type)) return false;
    if (status && row.status !== status) return false;
    return true;
  });

      const postingFees = rows.filter((r) => r.type.includes("fee") || r.type.includes("posting")).reduce((sum, r) => sum + r.amount, 0);
  const refunds = rows.filter((r) => r.type.includes("refund") || r.status === "refunded").reduce((sum, r) => sum + r.amount, 0);

  return (
    <div>
      <PageHeader title="Payments" description="Transactions, job posting fees, refunds, and settlement status." />
      {error ? <ErrorBanner message={error} onRetry={reload} /> : null}

      <div className="mb-4 grid gap-3 sm:grid-cols-3">
        <div className="card px-4 py-3">
          <p className="text-xs text-ink-500">Visible volume</p>
          <p className="mt-1 text-lg font-semibold">{formatINR(rows.reduce((sum, r) => sum + r.amount, 0))}</p>
        </div>
        <div className="card px-4 py-3">
          <p className="text-xs text-ink-500">Posting fees</p>
          <p className="mt-1 text-lg font-semibold">{formatINR(postingFees)}</p>
        </div>
        <div className="card px-4 py-3">
          <p className="text-xs text-ink-500">Refunds</p>
          <p className="mt-1 text-lg font-semibold">{formatINR(refunds)}</p>
        </div>
      </div>

      <div className="mb-4 flex flex-col gap-3">
        <SearchInput value={search} onChange={setSearch} placeholder="Search txn id, user, or job" />
        <div className="flex flex-wrap gap-2">
          {TYPE_FILTERS.map((item) => (
            <FilterChip key={item.value} active={type === item.value} onClick={() => setType(item.value)}>
              {item.label}
            </FilterChip>
          ))}
        </div>
        <div className="flex flex-wrap gap-2">
          {STATUS_FILTERS.map((item) => (
            <FilterChip key={item.value} active={status === item.value} onClick={() => setStatus(item.value)}>
              {item.label}
            </FilterChip>
          ))}
        </div>
      </div>

      <DataTable
        loading={loading}
        rows={rows}
        emptyTitle="No transactions"
        emptyHint="Payments appear after posting fees, completions, or refunds."
        columns={[
          { key: "txnId", header: "Txn", render: (p) => <span className="font-mono text-xs">{p.txnId}</span> },
          { key: "type", header: "Type", render: (p) => <StatusBadge value={p.type} /> },
          { key: "amount", header: "Amount", render: (p) => formatINR(p.amount) },
          { key: "commission", header: "Commission", render: (p) => (p.commission ? formatINR(p.commission) : "—") },
          { key: "net", header: "Net", render: (p) => (p.net ? formatINR(p.net) : "—") },
          { key: "status", header: "Status", render: (p) => <StatusBadge value={p.status} /> },
          { key: "user", header: "User", render: (p) => p.user },
          { key: "job", header: "Job", render: (p) => p.job },
          { key: "createdAt", header: "Date", render: (p) => formatDateTime(p.createdAt) },
        ]}
      />
    </div>
  );
}
