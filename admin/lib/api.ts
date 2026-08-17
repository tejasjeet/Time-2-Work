import { clearSession, getToken } from "./auth";
import {
  asObj,
  bool,
  displayName,
  entityId,
  num,
  paginationMeta,
  pick,
  str,
  unwrapList,
  unwrapObject,
  unwrapToken,
} from "./format";
import type { Analytics, AppUser, Category, Job, Paginated, Payment, Report, Settings } from "./types";

export const API_BASE = process.env.NEXT_PUBLIC_API_URL || "http://localhost:4000/api";

export class ApiError extends Error {
  status: number;
  constructor(message: string, status: number) {
    super(message);
    this.status = status;
  }
}

type RequestOptions = {
  method?: string;
  body?: unknown;
  query?: Record<string, string | number | boolean | undefined>;
  auth?: boolean;
};

function buildUrl(path: string, query?: RequestOptions["query"]) {
  const url = new URL(`${API_BASE}${path.startsWith("/") ? path : `/${path}`}`);
  if (query) {
    Object.entries(query).forEach(([key, value]) => {
      if (value !== undefined && value !== "" && value !== false) {
        url.searchParams.set(key, String(value));
      }
    });
  }
  return url.toString();
}

export async function api<T = unknown>(path: string, options: RequestOptions = {}): Promise<T> {
  const { method = "GET", body, query, auth = true } = options;
  const headers: Record<string, string> = { Accept: "application/json" };
  if (body !== undefined) headers["Content-Type"] = "application/json";
  if (auth) {
    const token = getToken();
    if (token) headers.Authorization = `Bearer ${token}`;
  }

  const res = await fetch(buildUrl(path, query), {
    method,
    headers,
    body: body === undefined ? undefined : JSON.stringify(body),
  });

  const text = await res.text();
  let json: unknown = null;
  if (text) {
    try {
      json = JSON.parse(text);
    } catch {
      json = { message: text };
    }
  }

  if (res.status === 401 && auth) {
    clearSession();
    if (typeof window !== "undefined") window.location.assign("/login");
    throw new ApiError("Session expired. Please sign in again.", 401);
  }

  if (!res.ok) {
    const obj = asObj(json);
    const nested = asObj(obj?.error);
    const message = str(nested?.message, obj?.message, obj?.error, obj?.msg, `Request failed (${res.status})`);
    throw new ApiError(message, res.status);
  }

  return json as T;
}

export async function loginAdmin(email: string, password: string) {
  const json = await api("/admin/login", { method: "POST", body: { email, password }, auth: false });
  const token = unwrapToken(json);
  if (!token) throw new ApiError("Login succeeded but no JWT was returned.", 500);
  return { token, raw: json };
}

export function normalizeAnalytics(raw: unknown): Analytics {
  const data = unwrapObject(raw);
  const users = asObj(data.users);
  const jobs = asObj(data.jobs);
  const revenue = asObj(data.revenue);
  const extra: Record<string, number> = {};
  const skip = new Set([
    "totalUsers",
    "users",
    "activeUsers",
    "active",
    "jobsPosted",
    "jobs",
    "jobsCompleted",
    "revenue",
    "totalRevenue",
    "commission",
    "totalCommission",
    "message",
    "success",
  ]);
  Object.entries(data).forEach(([key, value]) => {
    if (!skip.has(key) && (typeof value === "number" || (typeof value === "string" && Number.isFinite(Number(value))))) {
      extra[key] = num(value);
    }
  });
  return {
    totalUsers: num(data.totalUsers, data.userCount, users?.total, users?.count, data.users),
    activeUsers: num(data.activeUsers, data.active, users?.active, users?.activeCount),
    jobsPosted: num(data.jobsPosted, data.totalJobs, jobs?.posted, jobs?.total, jobs?.count, data.jobs),
    jobsCompleted: num(data.jobsCompleted, jobs?.completed, data.completedJobs),
    revenue: num(data.revenue, data.totalRevenue, revenue?.total, revenue?.amount, revenue?.gross),
    commission: num(data.commission, data.totalCommission, revenue?.commission),
    extra,
  };
}

export function normalizeUser(raw: unknown): AppUser {
  const obj = asObj(raw) ?? {};
  const profile = asObj(obj.profile) ?? asObj(obj.workerProfile) ?? asObj(obj.businessProfile);
  return {
    id: entityId(obj),
    name: str(obj.name, obj.fullName, profile?.name, obj.email, obj.phone) || "Unknown",
    email: str(obj.email),
    phone: str(obj.phone, obj.mobile, obj.phoneNumber),
    role: str(obj.role, obj.userType, "user") || "user",
    status: str(obj.status, "active").toLowerCase(),
    verified: bool(obj.verified, obj.isVerified, obj.kycVerified, profile?.verified),
    city: str(obj.address, obj.city, obj.area, asObj(obj.location)?.city, asObj(obj.address)?.city, asObj(obj.address)?.address),
    createdAt: str(obj.createdAt, obj.created_at),
    raw: obj,
  };
}

export function normalizeJob(raw: unknown): Job {
  const obj = asObj(raw) ?? {};
  const category = asObj(obj.category);
  const poster = asObj(obj.poster) ?? asObj(obj.owner) ?? asObj(obj.postedBy) ?? asObj(obj.user);
  const location = asObj(obj.location) ?? asObj(obj.address);
  return {
    id: entityId(obj),
    title: str(obj.title, obj.name) || "Untitled job",
    category: str(category?.name, obj.categoryName, obj.category),
    pay: num(obj.pay, obj.budget, obj.amount, obj.wage, obj.salary),
    status: str(obj.status, "open").toLowerCase(),
    poster: displayName(poster ?? obj.posterName ?? obj.ownerName),
    location: str(obj.address, location?.address, location?.area, location?.city, obj.area, obj.city),
    reported: bool(obj.reported, obj.isReported, obj.reportCount) || num(obj.reportCount, obj.reports) > 0,
    workersRequired: num(obj.workersRequired, obj.helpersNeeded, obj.slots, 1) || 1,
    createdAt: str(obj.createdAt, obj.created_at),
    raw: obj,
  };
}

export function normalizeCategory(raw: unknown): Category {
  const obj = asObj(raw) ?? {};
  return {
    id: entityId(obj),
    name: str(obj.name, obj.title) || "Untitled",
    slug: str(obj.slug),
    icon: str(obj.icon, obj.emoji),
    nameHi: str(obj.nameHi),
    description: str(obj.description),
    sortOrder: num(obj.sortOrder, obj.order, obj.position),
    isActive: obj.isActive === undefined && obj.active === undefined ? true : bool(obj.isActive, obj.active),
    raw: obj,
  };
}

export function normalizePayment(raw: unknown): Payment {
  const obj = asObj(raw) ?? {};
  return {
    id: entityId(obj),
    txnId: str(obj.uniqueTxnId, obj.txnId, obj.transactionId, obj.orderId, obj._id, obj.id),
    type: str(obj.type, obj.kind, obj.purpose, "payment").toLowerCase(),
    amount: num(obj.amount, obj.gross, obj.total),
    gross: num(obj.gross, obj.amount),
    commission: num(obj.commission, obj.commissionAmount),
    net: num(obj.net, obj.netAmount),
    status: str(obj.paymentStatus, obj.status, "pending").toLowerCase(),
    user: displayName(obj.user ?? obj.payer ?? obj.worker ?? obj.poster ?? obj.toUserId ?? obj.fromUserId ?? obj.userId),
    job: displayName(obj.job ?? obj.jobTitle ?? obj.jobId, "—"),
    createdAt: str(obj.createdAt, obj.created_at, obj.paidAt),
    raw: obj,
  };
}

export function normalizeReport(raw: unknown): Report {
  const obj = asObj(raw) ?? {};
  return {
    id: entityId(obj),
    reporter: displayName(obj.reporter ?? obj.reportedBy ?? obj.user),
    targetType: str(obj.targetType, obj.type, obj.entityType, "user").toLowerCase(),
    target: displayName(obj.target ?? obj.reportedUser ?? obj.job ?? obj.subject ?? obj.targetId, "—"),
    reason: str(obj.reason, obj.details, obj.message, obj.description, obj.complaint) || "—",
    status: str(obj.status, "open").toLowerCase(),
    createdAt: str(obj.createdAt, obj.created_at),
    raw: obj,
  };
}

export function normalizeSettings(raw: unknown): Settings {
  const root = unwrapObject(raw);
  const data = asObj(root.settings) ?? root;
  return {
    jobPostingFee: num(data.jobPostingFee, data.postingFee, 19),
    commissionPercent: num(data.commissionPercent, data.commission, 10),
    primaryRadiusKm: num(data.primaryRadiusKm, data.radiusKm, 5),
    secondaryRadiusKm: num(data.secondaryRadiusKm, data.extendedRadiusKm, 10),
    referralReward: num(data.referralReward, 0),
    raw: data,
  };
}

export async function fetchList<T>(
  path: string,
  keys: string[],
  map: (item: unknown) => T,
  query?: RequestOptions["query"],
): Promise<Paginated<T>> {
  const json = await api(path, { query });
  const items = unwrapList(json, keys).map(map);
  return { items, ...paginationMeta(json, items.length) };
}

export const adminApi = {
  analytics: () => api("/admin/analytics").then(normalizeAnalytics),
  users: (query?: RequestOptions["query"]) => {
    const q = { ...query };
    if (q.search && !q.q) q.q = q.search;
    return fetchList("/admin/users", ["users", "items", "results"], normalizeUser, q);
  },
  updateUser: (id: string, body: { status?: string; verified?: boolean }) =>
    api(`/admin/users/${id}`, { method: "PATCH", body }),
  jobs: (query?: RequestOptions["query"]) => fetchList("/admin/jobs", ["jobs", "items", "results"], normalizeJob, query),
  deleteJob: (id: string) => api(`/admin/jobs/${id}`, { method: "DELETE" }),
  categories: () => fetchList("/admin/categories", ["categories", "items", "results"], normalizeCategory),
  createCategory: (body: Record<string, unknown>) => api("/admin/categories", { method: "POST", body }),
  updateCategory: (id: string, body: Record<string, unknown>) => api(`/admin/categories/${id}`, { method: "PUT", body }),
  deleteCategory: (id: string) => api(`/admin/categories/${id}`, { method: "DELETE" }),
  payments: async (query?: RequestOptions["query"]) => {
    const json = await api("/admin/payments", { query });
    const root = asObj(json) ?? {};
    const paymentItems = unwrapList(root.payments ?? json, ["payments", "items"]).map(normalizePayment);
    const txnItems = unwrapList(root.transactions ?? json, ["transactions", "items"]).map(normalizePayment);
    const merged = txnItems.length || paymentItems.length ? [...paymentItems, ...txnItems] : unwrapList(json, ["payments", "transactions", "items"]).map(normalizePayment);
    const seen = new Set<string>();
    const items = merged.filter((item) => {
      const key = item.id || item.txnId;
      if (seen.has(key)) return false;
      seen.add(key);
      return true;
    });
    return { items, ...paginationMeta(asObj(root.transactions) ?? asObj(root.payments) ?? json, items.length) };
  },
  reports: (query?: RequestOptions["query"]) =>
    fetchList("/admin/reports", ["reports", "complaints", "items", "results"], normalizeReport, query),
  updateReport: (id: string, body: Record<string, unknown>) => api(`/admin/reports/${id}`, { method: "PATCH", body }),
  settings: () => api("/admin/settings").then(normalizeSettings),
  updateSettings: (body: Record<string, unknown>) => api("/admin/settings", { method: "PUT", body }),
};

export { pick };
