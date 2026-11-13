import { handleApi, json } from "@/lib/http";
import { requireUser } from "@/lib/auth";
import { query } from "@/lib/db";

export async function GET() {
  return handleApi(async () => {
    await requireUser();
    const rows = await query(
      `SELECT bg1.group_name AS donor, bg2.group_name AS recipient
         FROM blood_compatibility bc
         JOIN blood_group bg1 ON bg1.blood_group_id = bc.donor_group_id
         JOIN blood_group bg2 ON bg2.blood_group_id = bc.recipient_group_id
        ORDER BY bg1.group_name, bg2.group_name`
    );
    return json(rows);
  });
}
