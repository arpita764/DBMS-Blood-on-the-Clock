import { NextRequest } from "next/server";
import { handleApi, json, HttpError } from "@/lib/http";
import { requireUser } from "@/lib/auth";
import { query } from "@/lib/db";
import { reserveBlood } from "@/lib/procedures";

export async function GET(req: NextRequest) {
  return handleApi(async () => {
    await requireUser();
    const { searchParams } = new URL(req.url);
    const requestId = searchParams.get("request_id");
    let sql = `SELECT br.reservation_id, br.request_id, br.hospital_id,
                      hh.hospital_name AS supplier_hospital, br.blood_group_id,
                      bg.group_name, br.units_reserved, br.status, br.reserved_by,
                      u.full_name AS reserved_by_name, br.reserved_at
                 FROM blood_reservation br
                 JOIN hospital hh ON hh.hospital_id = br.hospital_id
                 JOIN blood_group bg ON bg.blood_group_id = br.blood_group_id
                 LEFT JOIN app_user u ON u.user_id = br.reserved_by`;
    const params: unknown[] = [];
    if (requestId) {
      sql += " WHERE br.request_id = ?";
      params.push(Number(requestId));
    }
    sql += " ORDER BY br.reserved_at DESC";
    return json(await query(sql, params));
  });
}

export async function POST(req: NextRequest) {
  return handleApi(async () => {
    const user = await requireUser();
    const b = await req.json();
    const out = await reserveBlood(
      Number(b.request_id),
      Number(b.supplier_hospital_id),
      Number(b.units),
      user.userId
    );
    const msg = String(out.message ?? "");
    if (msg.startsWith("ERROR")) throw new HttpError(400, msg);
    return json(out);
  });
}
