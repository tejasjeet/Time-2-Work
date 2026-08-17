import type { AdminUser } from "./types";
import { asObj, str } from "./format";

const TOKEN_KEY = "t2w_admin_token";
const USER_KEY = "t2w_admin_user";

export function getToken(): string | null {
  if (typeof window === "undefined") return null;
  return window.localStorage.getItem(TOKEN_KEY);
}

export function getAdminUser(): AdminUser | null {
  if (typeof window === "undefined") return null;
  const raw = window.localStorage.getItem(USER_KEY);
  if (!raw) return null;
  try {
    return JSON.parse(raw) as AdminUser;
  } catch {
    return null;
  }
}

export function persistSession(token: string, user?: AdminUser | null) {
  window.localStorage.setItem(TOKEN_KEY, token);
  document.cookie = `${TOKEN_KEY}=1; path=/; max-age=${60 * 60 * 24 * 7}; SameSite=Lax`;
  if (user) {
    window.localStorage.setItem(USER_KEY, JSON.stringify(user));
  }
}

export function clearSession() {
  window.localStorage.removeItem(TOKEN_KEY);
  window.localStorage.removeItem(USER_KEY);
  document.cookie = `${TOKEN_KEY}=; path=/; max-age=0`;
}

export function parseAdminUser(json: unknown): AdminUser | null {
  const root = asObj(json);
  if (!root) return null;
  const nested = asObj(root.admin) ?? asObj(root.user) ?? asObj(root.data) ?? root;
  const email = str(nested.email, root.email);
  const name = str(nested.name, nested.fullName, root.name);
  if (!email && !name) return { email: "admin@time2work.com", name: "Admin" };
  return {
    id: str(nested._id, nested.id),
    email: email || "admin@time2work.com",
    name: name || "Admin",
    role: str(nested.role, "admin"),
  };
}
