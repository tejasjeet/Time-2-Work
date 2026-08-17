export type Id = string;

export type UserStatus = "active" | "suspended" | "blocked" | "inactive";
export type JobStatus =
  | "draft"
  | "pending_payment"
  | "open"
  | "accepted"
  | "started"
  | "in_progress"
  | "completed"
  | "cancelled"
  | "removed"
  | "reported";
export type ReportStatus = "open" | "pending" | "reviewed" | "resolved" | "dismissed";
export type PaymentStatus = "pending" | "success" | "paid" | "failed" | "refunded" | "cancelled";
export type PaymentType = "posting_fee" | "commission" | "payout" | "refund" | "job_payment";

export type AdminUser = {
  id?: Id;
  email?: string;
  name?: string;
  role?: string;
};

export type Analytics = {
  totalUsers: number;
  activeUsers: number;
  jobsPosted: number;
  jobsCompleted: number;
  revenue: number;
  commission: number;
  extra?: Record<string, number>;
};

export type AppUser = {
  id: Id;
  name: string;
  email: string;
  phone: string;
  role: string;
  status: string;
  verified: boolean;
  city: string;
  createdAt: string;
  raw: Record<string, unknown>;
};

export type Job = {
  id: Id;
  title: string;
  category: string;
  pay: number;
  status: string;
  poster: string;
  location: string;
  reported: boolean;
  workersRequired: number;
  createdAt: string;
  raw: Record<string, unknown>;
};

export type Category = {
  id: Id;
  name: string;
  slug: string;
  icon: string;
  nameHi: string;
  description: string;
  sortOrder: number;
  isActive: boolean;
  raw: Record<string, unknown>;
};

export type Payment = {
  id: Id;
  txnId: string;
  type: string;
  amount: number;
  gross: number;
  commission: number;
  net: number;
  status: string;
  user: string;
  job: string;
  createdAt: string;
  raw: Record<string, unknown>;
};

export type Report = {
  id: Id;
  reporter: string;
  targetType: string;
  target: string;
  reason: string;
  status: string;
  createdAt: string;
  raw: Record<string, unknown>;
};

export type Settings = {
  jobPostingFee: number;
  commissionPercent: number;
  primaryRadiusKm: number;
  secondaryRadiusKm: number;
  referralReward: number;
  raw: Record<string, unknown>;
};

export type Paginated<T> = {
  items: T[];
  total: number;
  page: number;
  pages: number;
};
