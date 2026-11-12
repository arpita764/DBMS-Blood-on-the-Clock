import { NextRequest } from "next/server";
import { handleApi, json, HttpError } from "@/lib/http";
import { requireAdmin, hashPassword } from "@/lib/auth";
import { query, execute, getOne } from "@/lib/db";

export async function GET() {
  return handleApi(async () => {
    await requireAdmin();
    const rows = await query(
      `SELECT u.user_id, u.full_name, u.email, u.role, u.account_status,
              u.hospital_id, h.hospital_name
         FROM app_user u
         LEFT JOIN hospital h ON h.hospital_id = u.hospital_id
        ORDER BY u.user_id`
    );
    return json(rows);
  });
}

export async function POST(req: NextRequest) {
  return handleApi(async () => {
    await requireAdmin();
    const b = await req.json();
    const name = String(b.full_name || "").trim();
    const email = String(b.email || "").trim();
    const password = String(b.password || "");
    const role = String(b.role || "").trim();
    if (!name || !email || !password || !role) {
      throw new HttpError(400, "Name, email, password and role are required");
    }
    if (!["ADMIN", "HOSPITAL_STAFF"].includes(role)) {
      throw new HttpError(400, "Role must be ADMIN or HOSPITAL_STAFF");
    }
    const hospitalId = role === "ADMIN" ? null : b.hospital_id ? Number(b.hospital_id) : null;
    if (role === "HOSPITAL_STAFF" && !hospitalId) {
      throw new HttpError(400, "Hospital staff must be assigned to a hospital");
    }
    const dup = await getOne<{ c: number }>(
      "SELECT COUNT(*) AS c FROM app_user WHERE email = ?",
      [email]
    );
    if ((dup?.c ?? 0) > 0) throw new HttpError(409, "Email already registered");
    const hash = await hashPassword(password);
    const r = await execute(
      `INSERT INTO app_user (full_name, email, password_hash, role, account_status, hospital_id)
       VALUES (?,?,?,?,?,?)`,
      [name, email, hash, role, "ACTIVE", hospitalId]
    );
    return json({ user_id: r.insertId, message: "User created" });
  });
}
