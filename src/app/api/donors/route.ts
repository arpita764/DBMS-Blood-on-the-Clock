import { NextRequest } from "next/server";
import { handleApi, json, HttpError } from "@/lib/http";
import { requireUser } from "@/lib/auth";
import { query, execute } from "@/lib/db";

export async function GET(req: NextRequest) {
  return handleApi(async () => {
    await requireUser();
    const { searchParams } = new URL(req.url);
    const available = searchParams.get("available");
    const group = searchParams.get("group");
    let sql = `SELECT d.donor_id, d.donor_name, d.phone, d.city, d.blood_group_id,
                      bg.group_name, d.hospital_id, h.hospital_name,
                      d.availability_status, d.last_donation_date
                 FROM donor d
                 JOIN blood_group bg ON bg.blood_group_id = d.blood_group_id
                 JOIN hospital h ON h.hospital_id = d.hospital_id
                WHERE 1=1`;
    const params: unknown[] = [];
    if (available) {
      sql += " AND d.availability_status = ?";
      params.push(available);
    }
    if (group) {
      sql += " AND bg.group_name = ?";
      params.push(group);
    }
    sql += " ORDER BY d.donor_name";
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
    const name = String(b.donor_name || "").trim();
    const phone = String(b.phone || "").trim();
    const city = String(b.city || "").trim();
    const bloodGroupId = Number(b.blood_group_id);
    if (!name || !phone || !city || !bloodGroupId) {
      throw new HttpError(400, "Name, phone, city and blood group are required");
    }
    const r = await execute(
      `INSERT INTO donor (donor_name, phone, city, blood_group_id, hospital_id, availability_status)
       VALUES (?,?,?,?,?,COALESCE(?,'AVAILABLE'))`,
      [name, phone, city, bloodGroupId, hospitalId, b.availability_status ?? null]
    );
    return json({ donor_id: r.insertId, message: "Donor registered" });
  });
}
