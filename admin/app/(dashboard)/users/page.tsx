"use client";

import { useMemo, useState } from "react";
import { ConfirmDialog } from "@/components/ConfirmDialog";
import { DataTable } from "@/components/DataTable";
import { ErrorBanner } from "@/components/ErrorBanner";
import { PageHeader } from "@/components/PageHeader";
import { StatusBadge } from "@/components/StatusBadge";
import { useToast } from "@/components/Toast";
import { SearchInput, Select } from "@/components/Toolbar";
import { adminApi } from "@/lib/api";
import { formatDate } from "@/lib/format";
import type { AppUser } from "@/lib/types";
import { useAsync } from "@/lib/useAsync";
import { useDebouncedValue } from "@/lib/useDebouncedValue";

export default function UsersPage() {
  const toast = useToast();
  const [search, setSearch] = useState("");
  const [status, setStatus] = useState("");
  const [pending, setPending] = useState<{ user: AppUser; action: "suspend" | "block" | "activate" } | null>(null);
  const [busy, setBusy] = useState(false);

  const debouncedSearch = useDebouncedValue(search);
  const query = useMemo(
    () => ({ search: debouncedSearch.trim() || undefined, status: status || undefined }),
    [debouncedSearch, status],
  );
  const { data, loading, error, reload } = useAsync(() => adminApi.users(query), [query.search, query.status]);

  async function patchUser(id: string, body: { status?: string; verified?: boolean }, ok: string) {
    setBusy(true);
    try {
      await adminApi.updateUser(id, body);
      toast(ok);
      setPending(null);
      await reload();
    } catch (err) {
      toast(err instanceof Error ? err.message : "Update failed", "err");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div>
      <PageHeader title="Users" description="Search accounts, verify workers, and suspend or block abuse." />
      {error ? <ErrorBanner message={error} onRetry={reload} /> : null}

      <div className="mb-4 flex flex-col gap-3 sm:flex-row">
        <SearchInput value={search} onChange={setSearch} placeholder="Search name, email, or phone" />
        <Select
          value={status}
          onChange={setStatus}
          options={[
            { value: "", label: "All statuses" },
            { value: "active", label: "Active" },
            { value: "suspended", label: "Suspended" },
            { value: "blocked", label: "Blocked" },
          ]}
        />
      </div>

      <DataTable
        loading={loading}
        rows={(data?.items ?? []).filter((u) => (status ? u.status === status : true))}
        emptyTitle="No users found"
        emptyHint="Try a different search or status filter."
        columns={[
          { key: "name", header: "User", render: (u) => (
            <div>
              <p className="font-medium text-ink">{u.name}</p>
              <p className="text-xs text-ink-500">{u.email || u.phone || "—"}</p>
            </div>
          ) },
          { key: "phone", header: "Phone", render: (u) => u.phone || "—" },
          { key: "role", header: "Role", render: (u) => <StatusBadge value={u.role} /> },
          { key: "status", header: "Status", render: (u) => <StatusBadge value={u.status} /> },
          { key: "verified", header: "Verified", render: (u) => <StatusBadge value={u.verified ? "verified" : "pending"} /> },
          { key: "city", header: "Address", render: (u) => u.city || "—" },
          { key: "createdAt", header: "Joined", render: (u) => formatDate(u.createdAt) },
          { key: "actions", header: "", className: "text-right", render: (u) => (
            <div className="flex justify-end gap-1">
              <button type="button" className="btn-ghost" onClick={() => patchUser(u.id, { verified: !u.verified }, u.verified ? "Verification removed" : "User verified")}>
                {u.verified ? "Unverify" : "Verify"}
              </button>
              {u.status !== "active" ? (
                <button type="button" className="btn-ghost" onClick={() => setPending({ user: u, action: "activate" })}>
                  Activate
                </button>
              ) : null}
              {u.status !== "suspended" ? (
                <button type="button" className="btn-ghost" onClick={() => setPending({ user: u, action: "suspend" })}>
                  Suspend
                </button>
              ) : null}
              {u.status !== "blocked" ? (
                <button type="button" className="btn-ghost text-red-600 hover:bg-red-50" onClick={() => setPending({ user: u, action: "block" })}>
                  Block
                </button>
              ) : null}
            </div>
          ) },
        ]}
      />

      <ConfirmDialog
        open={Boolean(pending)}
        title={pending?.action === "block" ? "Block user" : pending?.action === "suspend" ? "Suspend user" : "Activate user"}
        message={
          pending
            ? `${pending.action === "activate" ? "Restore" : "Change"} ${pending.user.name} to ${pending.action === "activate" ? "active" : pending.action}?`
            : ""
        }
        confirmLabel={pending?.action === "block" ? "Block" : pending?.action === "suspend" ? "Suspend" : "Activate"}
        danger={pending?.action === "block"}
        busy={busy}
        onClose={() => setPending(null)}
        onConfirm={() => {
          if (!pending) return;
          const next = pending.action === "activate" ? "active" : pending.action === "suspend" ? "suspended" : "blocked";
          void patchUser(pending.user.id, { status: next }, `User ${next}`);
        }}
      />
    </div>
  );
}
