import { EmptyState } from "./EmptyState";
import { Spinner } from "./Spinner";

export type Column<T> = {
  key: string;
  header: string;
  className?: string;
  render?: (row: T) => React.ReactNode;
};

export function DataTable<T extends { id?: string }>({
  columns,
  rows,
  loading,
  emptyTitle,
  emptyHint,
  rowKey,
}: {
  columns: Column<T>[];
  rows: T[];
  loading?: boolean;
  emptyTitle?: string;
  emptyHint?: string;
  rowKey?: (row: T, index: number) => string;
}) {
  if (loading) return <Spinner />;
  if (!rows.length) return <EmptyState title={emptyTitle || "No records"} hint={emptyHint} />;

  return (
    <div className="table-wrap">
      <table className="min-w-full text-left text-sm">
        <thead className="bg-ink-50 text-xs uppercase tracking-wide text-ink-500">
          <tr>
            {columns.map((col) => (
              <th key={col.key} className={`px-4 py-3 font-medium ${col.className ?? ""}`}>
                {col.header}
              </th>
            ))}
          </tr>
        </thead>
        <tbody className="divide-y divide-ink-100">
          {rows.map((row, index) => (
            <tr key={rowKey?.(row, index) ?? row.id ?? String(index)} className="bg-white transition hover:bg-amber-50/40">
              {columns.map((col) => (
                <td key={col.key} className={`px-4 py-3 align-middle text-ink-800 ${col.className ?? ""}`}>
                  {col.render ? col.render(row) : String((row as Record<string, unknown>)[col.key] ?? "—")}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
