import { NextRequest } from "next/server";
import { handleApi, json } from "@/lib/http";
import { requireUser } from "@/lib/auth";
import { query } from "@/lib/db";

export async function GET(req: NextRequest) {
  return handleApi(async () => {
    await requireUser();
    const { searchParams } = new URL(req.url);
    const requestId = searchParams.get("request_id");
    let sql = `SELECT ra.allocation_id, ra.resource_request_id, ra.resource_id,
                      r.resource_name, hh.hospital_name AS supplier_hospital,
                      ra.quantity_allocated, ra.status, ra.allocated_by,
                      u.full_name AS allocated_by_name, ra.allocated_at,
                      ra.released_by, ra.released_at
                 FROM resource_allocation ra
                 JOIN resource r ON r.resource_id = ra.resource_id
                 JOIN hospital hh ON hh.hospital_id = r.hospital_id
                 LEFT JOIN app_user u ON u.user_id = ra.allocated_by`;
    const params: unknown[] = [];
    if (requestId) {
      sql += " WHERE ra.resource_request_id = ?";
      params.push(Number(requestId));
    }
    sql += " ORDER BY ra.allocated_at DESC";
    return json(await query(sql, params));
  });
}
