"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { apiFetch } from "@/lib/api-client";
import type { SessionUser } from "@/lib/session";
import { cn } from "./ui";

type NavItem = { href: string; label: string; tag?: string };

const NAV: NavItem[] = [
  { href: "/", label: "Dashboard" },
  { href: "/blood/inventory", label: "Blood Inventory" },
  { href: "/blood/requests", label: "Blood Requests" },
  { href: "/resources/inventory", label: "Resource Inventory" },
  { href: "/resources/requests", label: "Resource Requests" },
  { href: "/donors", label: "Donors" },
  { href: "/hospitals", label: "Hospitals" },
  { href: "/cases", label: "Emergency Cases", tag: "Vector" },
];

export function Shell({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<SessionUser | null>(null);
  const [loading, setLoading] = useState(true);
  const pathname = usePathname();
  const router = useRouter();

  useEffect(() => {
    apiFetch<{ user: SessionUser | null }>("/api/auth/me")
      .then((d) => setUser(d.user))
      .catch(() => setUser(null))
      .finally(() => setLoading(false));
  }, []);

  async function signOut() {
    try {
      await apiFetch("/api/auth/logout", { method: "POST" });
    } catch {
      /* ignore */
    }
    router.push("/login");
  }

  const nav = [...NAV];
  if (user?.role === "ADMIN") nav.push({ href: "/admin/users", label: "User Management" });

  if (loading) {
    return (
      <div className="flex min-h-screen items-center justify-center text-gray-400">
        Loading…
      </div>
    );
  }

  return (
    <div className="flex min-h-screen">
      <aside className="flex w-60 flex-col border-r border-gray-200 bg-white">
        <div className="px-4 py-4">
          <div className="text-lg font-bold text-brand-700">Blood on the Clock</div>
          <div className="text-xs text-gray-400">Emergency coordination</div>
        </div>
        <nav className="flex-1 space-y-0.5 px-2">
          {nav.map((n) => (
            <Link
              key={n.href}
              href={n.href}
              className={cn(
                "flex items-center justify-between rounded-lg px-3 py-2 text-sm",
                pathname === n.href
                  ? "bg-brand-50 font-medium text-brand-700"
                  : "text-gray-600 hover:bg-gray-50"
              )}
            >
              <span>{n.label}</span>
              {n.tag && (
                <span className="rounded bg-purple-100 px-1.5 text-[10px] text-purple-700">
                  {n.tag}
                </span>
              )}
            </Link>
          ))}
        </nav>
        <div className="border-t border-gray-100 p-3">
          <div className="truncate text-sm font-medium text-gray-700">{user?.name}</div>
          <div className="mb-2 text-xs text-gray-400">
            {user?.role === "ADMIN"
              ? "Administrator"
              : "Hospital Staff"}
            {user?.hospitalId ? ` · Hospital ${user.hospitalId}` : ""}
          </div>
          <button
            onClick={signOut}
            className="text-xs text-red-600 hover:underline"
          >
            Sign out
          </button>
        </div>
      </aside>
      <main className="flex-1 overflow-auto bg-gray-50 p-6">{children}</main>
    </div>
  );
}
