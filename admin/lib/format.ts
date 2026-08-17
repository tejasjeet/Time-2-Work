export function asObj(value: unknown): Record<string, unknown> | null {
  if (value && typeof value === "object" && !Array.isArray(value)) {
    return value as Record<string, unknown>;
  }
  return null;
}

export function pick<T = unknown>(obj: Record<string, unknown> | null | undefined, ...keys: string[]): T | undefined {
  if (!obj) return undefined;
  for (const key of keys) {
    const value = obj[key];
    if (value !== undefined && value !== null && value !== "") return value as T;
  }
  return undefined;
}

export function entityId(obj: Record<string, unknown> | null | undefined): string {
  const id = pick<string | number>(obj, "_id", "id");
  return id === undefined ? "" : String(id);
}

export function num(...values: unknown[]): number {
  for (const value of values) {
    if (typeof value === "number" && Number.isFinite(value)) return value;
    if (typeof value === "string" && value.trim() !== "" && Number.isFinite(Number(value))) {
      return Number(value);
    }
  }
  return 0;
}

export function bool(...values: unknown[]): boolean {
  for (const value of values) {
    if (typeof value === "boolean") return value;
    if (value === "true" || value === 1 || value === "1") return true;
    if (value === "false" || value === 0 || value === "0") return false;
  }
  return false;
}

export function str(...values: unknown[]): string {
  for (const value of values) {
    if (typeof value === "string" && value.trim()) return value;
    if (typeof value === "number" && Number.isFinite(value)) return String(value);
  }
  return "";
}

export function displayName(value: unknown, fallback = "—"): string {
  if (!value) return fallback;
  if (typeof value === "string") return value || fallback;
  const obj = asObj(value);
  if (!obj) return fallback;
  return str(obj.name, obj.fullName, obj.email, obj.phone, obj.title, obj._id, obj.id) || fallback;
}

export function formatINR(value: number): string {
  return new Intl.NumberFormat("en-IN", {
    style: "currency",
    currency: "INR",
    maximumFractionDigits: value % 1 === 0 ? 0 : 2,
  }).format(value || 0);
}

export function formatNumber(value: number): string {
  return new Intl.NumberFormat("en-IN").format(value || 0);
}

export function formatDate(value: string | undefined): string {
  if (!value) return "—";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  return new Intl.DateTimeFormat("en-IN", {
    day: "2-digit",
    month: "short",
    year: "numeric",
  }).format(date);
}

export function formatDateTime(value: string | undefined): string {
  if (!value) return "—";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  return new Intl.DateTimeFormat("en-IN", {
    day: "2-digit",
    month: "short",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  }).format(date);
}

export function titleCase(value: string): string {
  return value
    .replace(/[_-]+/g, " ")
    .replace(/\s+/g, " ")
    .trim()
    .replace(/\b\w/g, (c) => c.toUpperCase());
}

export function unwrapList<T = unknown>(json: unknown, keys: string[]): T[] {
  if (Array.isArray(json)) return json as T[];
  const root = asObj(json);
  if (!root) return [];
  if (Array.isArray(root.data)) return root.data as T[];
  const data = asObj(root.data) ?? root;
  for (const key of keys) {
    const value = data[key];
    if (Array.isArray(value)) return value as T[];
    const nested = asObj(value);
    if (nested && Array.isArray(nested.data)) return nested.data as T[];
  }
  return [];
}

export function unwrapObject(json: unknown): Record<string, unknown> {
  const root = asObj(json);
  if (!root) return {};
  const data = asObj(root.data);
  return data ?? root;
}

export function unwrapToken(json: unknown): string {
  const root = asObj(json);
  if (!root) return "";
  const data = asObj(root.data);
  return str(
    root.token,
    root.accessToken,
    root.access_token,
    root.jwt,
    data?.token,
    data?.accessToken,
    data?.access_token,
  );
}

export function paginationMeta(json: unknown, itemCount: number) {
  const root = asObj(json);
  const meta = asObj(root?.meta) ?? asObj(asObj(root?.data)?.meta);
  const data = asObj(root?.data) ?? root;
  const total = num(meta?.total, data?.total, data?.count, data?.totalCount, itemCount);
  const page = num(meta?.page, data?.page, data?.currentPage, 1) || 1;
  const limit = num(meta?.limit, 20) || 20;
  const pages = num(meta?.pages, data?.totalPages, Math.max(1, Math.ceil(total / limit)));
  return { total, page, pages };
}
