import { NextRequest } from "next/server";
import { handleApi, json } from "@/lib/http";
import { requireUser } from "@/lib/auth";
import { query } from "@/lib/db";

export async function GET(req: NextRequest) {
  return handleApi(async () => {
    await requireUser();
    const { searchParams } = new URL(req.url);
    const city = searchParams.get("city");
    const type = searchParams.get("type");
    let sql = `SELECT r.resource_id, r.hospital_id, h.hospital_name, h.city,
                      r.resource_name, r.resource_type, r.total_quantity,
                      r.available_quantity, r.status
                 FROM resource r
                 JOIN hospital h ON h.hospital_id = r.hospital_id
                WHERE 1=1`;
    const params: unknown[] = [];
    if (city) {
      sql += " AND h.city = ?";
      params.push(city);
    }
    if (type) {
      sql += " AND r.resource_type = ?";
      params.push(type);
    }
    sql += " ORDER BY h.city, r.resource_type, r.resource_name";
    return json(await query(sql, params));
  });
}
