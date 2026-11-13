import { NextRequest } from "next/server";
import { handleApi, json } from "@/lib/http";
import { requireUser } from "@/lib/auth";
import { query } from "@/lib/db";

export async function GET(req: NextRequest) {
  return handleApi(async () => {
    await requireUser();
    const { searchParams } = new URL(req.url);
    const city = searchParams.get("city");
    const group = searchParams.get("group");
    let sql = "SELECT * FROM available_blood_by_hospital WHERE 1=1";
    const params: unknown[] = [];
    if (city) {
      sql += " AND city = ?";
      params.push(city);
    }
    if (group) {
      sql += " AND blood_group = ?";
      params.push(group);
    }
    sql += " ORDER BY available_units DESC";
    return json(await query(sql, params));
  });
}
