import "server-only";
import bcrypt from "bcryptjs";
import { cookies } from "next/headers";
import { query } from "./db";
import { HttpError } from "./http";
import {
  createSessionToken,
  verifySessionToken,
  SESSION_COOKIE,
  type SessionUser,
} from "./session";

export { createSessionToken, verifySessionToken, SESSION_COOKIE };
export type { SessionUser };

const BCRYPT_COST = 12;

export async function hashPassword(plain: string): Promise<string> {
  return bcrypt.hash(plain, BCRYPT_COST);
}

export async function verifyPassword(
  plain: string,
  hash: string
): Promise<boolean> {
  return bcrypt.compare(plain, hash);
}

/** Validate email + password against the app_user table. */
export async function authenticate(
  email: string,
  password: string
): Promise<SessionUser | null> {
  const rows = await query<{
    user_id: number;
    full_name: string;
    email: string;
    password_hash: string;
    role: "ADMIN" | "HOSPITAL_STAFF";
    account_status: "ACTIVE" | "DISABLED";
    hospital_id: number | null;
  }>(
    `SELECT user_id, full_name, email, password_hash, role,
            account_status, hospital_id
     FROM app_user WHERE email = ? LIMIT 1`,
    [email]
  );
  const u = rows[0];
  if (!u || u.account_status !== "ACTIVE") return null;
  const ok = await bcrypt.compare(password, u.password_hash);
  if (!ok) return null;
  return {
    userId: u.user_id,
    role: u.role,
    hospitalId: u.hospital_id,
    name: u.full_name,
    email: u.email,
  };
}

/** Read the session user from the request cookies (server runtime only). */
export async function getCurrentUser(): Promise<SessionUser | null> {
  const token = cookies().get(SESSION_COOKIE)?.value;
  return verifySessionToken(token);
}

export async function requireUser(): Promise<SessionUser> {
  const u = await getCurrentUser();
  if (!u) throw new HttpError(401, "Unauthorized");
  return u;
}

export async function requireAdmin(): Promise<SessionUser> {
  const u = await requireUser();
  if (u.role !== "ADMIN") throw new HttpError(403, "Forbidden");
  return u;
}
