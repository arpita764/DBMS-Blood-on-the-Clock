import { handleApi, json } from "@/lib/http";
import { requireUser } from "@/lib/auth";
import { query } from "@/lib/db";

export async function GET() {
  return handleApi(async () => {
    await requireUser();
    return json(
      await query(
        "SELECT blood_group_id, group_name FROM blood_group ORDER BY group_name"
      )
    );
  });
}
