import { NextRequest } from "next/server";
import { handleApi, json, HttpError } from "@/lib/http";
import { requireUser } from "@/lib/auth";
import { query, execute } from "@/lib/db";

export async function GET(req: NextRequest) {
  return handleApi(async () => {
    await requireUser();
    const { searchParams } = new URL(req.url);
    const status = searchParams.get("status");
    let sql = `SELECT er.request_id, er.hospital_id, h.hospital_name, h.city,
                     er.blood_group_id, bg.group_name, er.quantity_required,
                     er.priority, er.status, er.created_at, er.required_by,
                     er.created_by, u.full_name AS created_by_name
                FROM emergency_request er
                JOIN hospital h ON h.hospital_id = er.hospital_id
                JOIN blood_group bg ON bg.blood_group_id = er.blood_group_id
                LEFT JOIN app_user u ON u.user_id = er.created_by`;
    const params: unknown[] = [];
    if (status) {
      sql += " WHERE er.status = ?";
      params.push(status);
    }
    sql += " ORDER BY er.created_at DESC";
    return json(await query(sql, params));
  });
}

export async function POST(req: NextRequest) {
  return handleApi(async () => {
    const user = await requireUser();
    const b = await req.json();
    const hospitalId =
      user.role === "ADMIN" ? Number(b.hospital_id) : user.hospitalId;
    if (!hospitalId) throw new HttpError(400, "Hospital is required");
    const bloodGroupId = Number(b.blood_group_id);
    const qty = Number(b.quantity_required);
    const priority = String(b.priority || "MEDIUM");
    const requiredBy = String(b.required_by || "");
    if (!bloodGroupId || !qty || qty <= 0 || !requiredBy) {
      throw new HttpError(
        400,
        "Blood group, quantity (>0) and required-by date are required"
      );
    }
    const r = await execute(
      `INSERT INTO emergency_request
         (hospital_id, blood_group_id, quantity_required, priority, required_by, created_by)
       VALUES (?,?,?,?,?,?)`,
      [hospitalId, bloodGroupId, qty, priority, requiredBy, user.userId]
    );
    return json({ request_id: r.insertId, message: "Emergency request created" });
  });
}
