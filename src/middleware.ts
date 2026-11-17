import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";
import { verifySessionToken, SESSION_COOKIE } from "@/lib/session";

export async function middleware(req: NextRequest) {
  const { pathname } = req.nextUrl;

  // Public paths: the login page and the login/logout endpoints.
  if (pathname === "/login") return NextResponse.next();
  if (pathname === "/api/auth/login" || pathname === "/api/auth/logout") {
    return NextResponse.next();
  }

  const token = req.cookies.get(SESSION_COOKIE)?.value;
  const user = await verifySessionToken(token);

  // All API routes require a valid session.
  if (pathname.startsWith("/api/")) {
    if (!user) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    if (pathname.startsWith("/api/admin/") && user.role !== "ADMIN") {
      return NextResponse.json({ error: "Forbidden" }, { status: 403 });
    }
    return NextResponse.next();
  }

  // All pages require a valid session.
  if (!user) return NextResponse.redirect(new URL("/login", req.url));
  if (pathname.startsWith("/admin") && user.role !== "ADMIN") {
    return NextResponse.redirect(new URL("/", req.url));
  }
  return NextResponse.next();
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico).*)"],
};
