import { NextRequest } from "next/server";
import { handleApi, json, HttpError } from "@/lib/http";
import { authenticate, createSessionToken } from "@/lib/auth";
import { SESSION_COOKIE } from "@/lib/session";

export async function POST(req: NextRequest) {
  return handleApi(async () => {
    const body = await req.json().catch(() => ({}) as Record<string, unknown>);
    const email = String(body.email ?? "").trim();
    const password = String(body.password ?? "");
    if (!email || !password) {
      throw new HttpError(400, "Email and password are required");
    }
    const user = await authenticate(email, password);
    if (!user) throw new HttpError(401, "Invalid email or password");
    const token = await createSessionToken(user);
    const res = json({ user });
    res.headers.set(
      "set-cookie",
      `${SESSION_COOKIE}=${token}; HttpOnly; Path=/; SameSite=Lax; Max-Age=604800`
    );
    return res;
  });
}
