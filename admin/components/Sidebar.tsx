"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { clearSession, getAdminUser } from "@/lib/auth";
import { useEffect, useState } from "react";
import {
  IconBriefcase,
  IconCard,
  IconClose,
  IconDashboard,
  IconFlag,
  IconFolder,
  IconLogout,
  IconMenu,
  IconSettings,
  IconUsers,
} from "./icons";

const NAV = [
  { href: "/", label: "Dashboard", icon: IconDashboard },
  { href: "/users", label: "Users", icon: IconUsers },
  { href: "/jobs", label: "Jobs", icon: IconBriefcase },
  { href: "/categories", label: "Categories", icon: IconFolder },
  { href: "/payments", label: "Payments", icon: IconCard },
  { href: "/reports", label: "Reports", icon: IconFlag },
  { href: "/settings", label: "Settings", icon: IconSettings },
];

function isActive(pathname: string, href: string) {
  if (href === "/") return pathname === "/";
  return pathname === href || pathname.startsWith(`${href}/`);
}

export function Sidebar() {
  const pathname = usePathname();
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const [email, setEmail] = useState("admin@time2work.com");

  useEffect(() => {
    setEmail(getAdminUser()?.email || "admin@time2work.com");
  }, []);

  useEffect(() => {
    setOpen(false);
  }, [pathname]);

  function logout() {
    clearSession();
    router.replace("/login");
  }

  return (
    <>
      <header className="sticky top-0 z-30 flex items-center justify-between border-b border-ink-200 bg-white px-4 py-3 lg:hidden">
        <div className="flex items-center gap-2">
          <span className="flex h-8 w-8 items-center justify-center rounded-lg bg-amber-500 text-sm font-bold text-black">T2</span>
          <span className="font-semibold text-ink">Time2Work</span>
        </div>
        <button type="button" className="rounded-lg p-2 text-ink hover:bg-ink-50" onClick={() => setOpen(true)} aria-label="Open menu">
          <IconMenu className="h-5 w-5" />
        </button>
      </header>

      {open ? <button type="button" className="fixed inset-0 z-40 bg-black/40 lg:hidden" aria-label="Close menu" onClick={() => setOpen(false)} /> : null}

      <aside
        className={`fixed inset-y-0 left-0 z-50 flex w-64 flex-col bg-ink text-white transition-transform lg:static lg:translate-x-0 ${
          open ? "translate-x-0" : "-translate-x-full"
        }`}
      >
        <div className="flex items-center justify-between px-5 py-6">
          <Link href="/" className="flex items-center gap-3">
            <span className="flex h-9 w-9 items-center justify-center rounded-xl bg-amber-500 text-sm font-bold text-black">T2</span>
            <div>
              <p className="text-sm font-semibold leading-none">Time2Work</p>
              <p className="mt-1 text-[11px] text-white/50">Admin console</p>
            </div>
          </Link>
          <button type="button" className="rounded-lg p-1 text-white/70 hover:bg-white/10 lg:hidden" onClick={() => setOpen(false)} aria-label="Close menu">
            <IconClose className="h-4 w-4" />
          </button>
        </div>

        <nav className="flex-1 space-y-1 px-3">
          {NAV.map((item) => {
            const active = isActive(pathname, item.href);
            const Icon = item.icon;
            return (
              <Link
                key={item.href}
                href={item.href}
                className={`flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm transition ${
                  active ? "bg-white/10 font-medium text-amber-400" : "text-white/70 hover:bg-white/5 hover:text-white"
                }`}
              >
                <span className={`h-5 w-1 rounded-full ${active ? "bg-amber-500" : "bg-transparent"}`} />
                <Icon className="h-4 w-4" />
                {item.label}
              </Link>
            );
          })}
        </nav>

        <div className="border-t border-white/10 p-4">
          <p className="truncate px-2 text-xs text-white/50">{email}</p>
          <button type="button" onClick={logout} className="mt-2 flex w-full items-center gap-2 rounded-xl px-3 py-2 text-sm text-white/70 hover:bg-white/5 hover:text-white">
            <IconLogout className="h-4 w-4" />
            Sign out
          </button>
        </div>
      </aside>
    </>
  );
}
