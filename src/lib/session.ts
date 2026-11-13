// Edge-safe session helpers (JWT via jose). Imported by both server route
// handlers (Node runtime) and middleware (Edge runtime), so it must NOT
// import any Node-only or "server-only" modules.

import { SignJWT, jwtVerify } from "jose";

export const SESSION_COOKIE = "botc_session";

export interface SessionUser {
  userId: number;
  role: "ADMIN" | "HOSPITAL_STAFF";
  hospitalId: number | null;
  name: string;
  email: string;
}

function getSecret(): Uint8Array {
  return new TextEncoder().encode(
    process.env.JWT_SECRET ||
      "dev-secret-please-change-me-to-a-long-random-string-32chars"
  );
}

export async function createSessionToken(user: SessionUser): Promise<string> {
  return new SignJWT({
    userId: user.userId,
    role: user.role,
    hospitalId: user.hospitalId,
    name: user.name,
    email: user.email,
  })
    .setProtectedHeader({ alg: "HS256" })
    .setIssuedAt()
    .setExpirationTime("7d")
    .sign(getSecret());
}

export async function verifySessionToken(
  token?: string
): Promise<SessionUser | null> {
  if (!token) return null;
  try {
    const { payload } = await jwtVerify(token, getSecret());
    return {
      userId: Number(payload.userId),
      role: payload.role as SessionUser["role"],
      hospitalId:
        payload.hospitalId === null || payload.hospitalId === undefined
          ? null
          : Number(payload.hospitalId),
      name: String(payload.name ?? ""),
      email: String(payload.email ?? ""),
    };
  } catch {
    return null;
  }
}
