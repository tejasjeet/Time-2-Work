"use client";

import { FormEvent, useState } from "react";
import { ConfirmDialog } from "@/components/ConfirmDialog";
import { DataTable } from "@/components/DataTable";
import { ErrorBanner } from "@/components/ErrorBanner";
import { PageHeader } from "@/components/PageHeader";
import { StatusBadge } from "@/components/StatusBadge";
import { useToast } from "@/components/Toast";
import { IconClose, IconPlus } from "@/components/icons";
import { adminApi } from "@/lib/api";
import type { Category } from "@/lib/types";
import { useAsync } from "@/lib/useAsync";

const emptyForm = { name: "", slug: "", nameHi: "", icon: "", description: "", sortOrder: 0, isActive: true };

function slugify(value: string) {
  return value
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
}

export default function CategoriesPage() {
  const toast = useToast();
  const { data, loading, error, reload } = useAsync(() => adminApi.categories(), []);
  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState<Category | null>(null);
  const [form, setForm] = useState(emptyForm);
  const [remove, setRemove] = useState<Category | null>(null);
  const [busy, setBusy] = useState(false);

  function startCreate() {
    setEditing(null);
    setForm(emptyForm);
    setOpen(true);
  }

  function startEdit(category: Category) {
    setEditing(category);
    setForm({
      name: category.name,
      slug: category.slug,
      nameHi: category.nameHi,
      icon: category.icon,
      description: category.description,
      sortOrder: category.sortOrder,
      isActive: category.isActive,
    });
    setOpen(true);
  }

  async function onSubmit(event: FormEvent) {
    event.preventDefault();
    setBusy(true);
    const body = {
      name: form.name.trim(),
      slug: (form.slug || slugify(form.name)).trim(),
      nameHi: form.nameHi.trim(),
      icon: form.icon.trim(),
      description: form.description.trim(),
      sortOrder: Number(form.sortOrder) || 0,
      isActive: form.isActive,
      active: form.isActive,
    };
    try {
      if (editing) await adminApi.updateCategory(editing.id, body);
      else await adminApi.createCategory(body);
      toast(editing ? "Category updated" : "Category created");
      setOpen(false);
      await reload();
    } catch (err) {
      toast(err instanceof Error ? err.message : "Save failed", "err");
    } finally {
      setBusy(false);
    }
  }

  async function onDelete() {
    if (!remove) return;
    setBusy(true);
    try {
      await adminApi.deleteCategory(remove.id);
      toast("Category deleted");
      setRemove(null);
      await reload();
    } catch (err) {
      toast(err instanceof Error ? err.message : "Delete failed", "err");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div>
      <PageHeader
        title="Categories"
        description="Create and maintain job categories used by the mobile feed."
        actions={
          <button type="button" className="btn-primary" onClick={startCreate}>
            <IconPlus className="h-4 w-4" />
            New category
          </button>
        }
      />
      {error ? <ErrorBanner message={error} onRetry={reload} /> : null}

      <DataTable
        loading={loading}
        rows={data?.items ?? []}
        emptyTitle="No categories yet"
        emptyHint="Add the first category to power job matching."
        columns={[
          { key: "name", header: "Category", render: (c) => (
            <div className="flex items-center gap-2">
              <span className="flex h-8 w-8 items-center justify-center rounded-lg bg-amber-50 text-sm">{c.icon || "•"}</span>
              <div>
                <p className="font-medium">{c.name}</p>
                <p className="text-xs text-ink-500">{c.nameHi ? `${c.nameHi} · ` : ""}{c.slug || "—"}</p>
              </div>
            </div>
          ) },
          { key: "description", header: "Description", render: (c) => <span className="text-ink-600">{c.description || "—"}</span> },
          { key: "sortOrder", header: "Order", render: (c) => String(c.sortOrder) },
          { key: "isActive", header: "Status", render: (c) => <StatusBadge value={c.isActive ? "active" : "inactive"} /> },
          { key: "actions", header: "", className: "text-right", render: (c) => (
            <div className="flex justify-end gap-1">
              <button type="button" className="btn-ghost" onClick={() => startEdit(c)}>
                Edit
              </button>
              <button type="button" className="btn-ghost text-red-600 hover:bg-red-50" onClick={() => setRemove(c)}>
                Delete
              </button>
            </div>
          ) },
        ]}
      />

      {open ? (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <form onSubmit={onSubmit} className="card w-full max-w-lg p-6">
            <div className="mb-4 flex items-center justify-between">
              <h2 className="text-lg font-semibold">{editing ? "Edit category" : "New category"}</h2>
              <button type="button" className="rounded-lg p-1 text-ink-400 hover:bg-ink-50" onClick={() => setOpen(false)} aria-label="Close">
                <IconClose className="h-4 w-4" />
              </button>
            </div>
            <div className="grid gap-4 sm:grid-cols-2">
              <div className="sm:col-span-2">
                <label className="label">Name</label>
                <input
                  className="input"
                  required
                  value={form.name}
                  onChange={(e) => setForm((f) => ({ ...f, name: e.target.value, slug: f.slug || slugify(e.target.value) }))}
                />
              </div>
              <div>
                <label className="label">Slug</label>
                <input className="input" required value={form.slug} onChange={(e) => setForm((f) => ({ ...f, slug: e.target.value }))} />
              </div>
              <div>
                <label className="label">Hindi name</label>
                <input className="input" value={form.nameHi} onChange={(e) => setForm((f) => ({ ...f, nameHi: e.target.value }))} />
              </div>
              <div>
                <label className="label">Icon / emoji</label>
                <input className="input" value={form.icon} onChange={(e) => setForm((f) => ({ ...f, icon: e.target.value }))} />
              </div>
              <div>
                <label className="label">Sort order</label>
                <input
                  className="input"
                  type="number"
                  value={form.sortOrder}
                  onChange={(e) => setForm((f) => ({ ...f, sortOrder: Number(e.target.value) }))}
                />
              </div>
              <div className="flex items-end pb-2">
                <label className="flex items-center gap-2 text-sm">
                  <input type="checkbox" checked={form.isActive} onChange={(e) => setForm((f) => ({ ...f, isActive: e.target.checked }))} />
                  Active
                </label>
              </div>
              <div className="sm:col-span-2">
                <label className="label">Description</label>
                <textarea className="input min-h-24" value={form.description} onChange={(e) => setForm((f) => ({ ...f, description: e.target.value }))} />
              </div>
            </div>
            <div className="mt-6 flex justify-end gap-2">
              <button type="button" className="btn-secondary" onClick={() => setOpen(false)}>
                Cancel
              </button>
              <button type="submit" className="btn-primary" disabled={busy}>
                {busy ? "Saving…" : "Save"}
              </button>
            </div>
          </form>
        </div>
      ) : null}

      <ConfirmDialog
        open={Boolean(remove)}
        title="Delete category"
        message={remove ? `Delete “${remove.name}”? Jobs using it may need remapping.` : ""}
        confirmLabel="Delete"
        danger
        busy={busy}
        onClose={() => setRemove(null)}
        onConfirm={() => void onDelete()}
      />
    </div>
  );
}
