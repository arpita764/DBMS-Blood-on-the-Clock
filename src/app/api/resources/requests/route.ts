import { NextRequest } from "next/server";
import { handleApi, json, HttpError } from "@/lib/http";
import { requireUser } from "@/lib/auth";
import { query, execute } from "@/lib/db";

export async function GET(req: NextRequest) {
  return handleApi(async () => {
    await requireUser();
    const { searchParams } = new URL(req.url);
    const status = searchParams.get("status");
    let sql = `SELECT rr.resource_request_id, rr.hospital_id, h.hospital_name,
                      h.city, rr.resource_type, rr.quantity_required, rr.priority,
                      rr.status, rr.created_at, rr.required_by, rr.created_by,
                      u.full_name AS created_by_name
                 FROM resource_request rr
                 JOIN hospital h ON h.hospital_id = rr.hospital_id
                 LEFT JOIN app_user u ON u.user_id = rr.created_by
                WHERE 1=1`;
    const params: unknown[] = [];
    if (status) {
      sql += " AND rr.status = ?";
      params.push(status);
    }
    sql += " ORDER BY rr.created_at DESC";
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
    const resourceType = String(b.resource_type || "").trim();
    const qty = Number(b.quantity_required);
    const priority = String(b.priority || "MEDIUM");
    const requiredBy = String(b.required_by || "");
    if (!resourceType || !qty || qty <= 0 || !requiredBy) {
      throw new HttpError(400, "Resource type, quantity (>0) and required-by date are required");
    }
    const r = await execute(
      `INSERT INTO resource_request
         (hospital_id, resource_type, quantity_required, priority, required_by, created_by)
       VALUES (?,?,?,?,?,?)`,
      [hospitalId, resourceType, qty, priority, requiredBy, user.userId]
    );
    return json({ resource_request_id: r.insertId, message: "Resource request created" });
  });
}
