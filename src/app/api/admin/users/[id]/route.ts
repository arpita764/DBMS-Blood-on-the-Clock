import { NextRequest } from "next/server";
import { handleApi, json, HttpError } from "@/lib/http";
import { requireAdmin } from "@/lib/auth";
import { execute } from "@/lib/db";

export async function PATCH(
  req: NextRequest,
  { params }: { params: { id: string } }
) {
  return handleApi(async () => {
    await requireAdmin();
    const b = await req.json();
    const status = String(b.account_status || "").trim();
    if (!["ACTIVE", "DISABLED"].includes(status)) {
      throw new HttpError(400, "account_status must be ACTIVE or DISABLED");
    }
    await execute(
      "UPDATE app_user SET account_status = ? WHERE user_id = ?",
      [status, Number(params.id)]
    );
    return json({ message: `User ${status.toLowerCase()}` });
  });
}
