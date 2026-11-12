import { NextRequest } from "next/server";
import { handleApi, json, HttpError } from "@/lib/http";
import { requireUser } from "@/lib/auth";
import { updateCaseStatus } from "@/lib/vector";
import type { EmergencyCase } from "@/lib/types";

export async function POST(
  req: NextRequest,
  { params }: { params: { id: string } }
) {
  return handleApi(async () => {
    const user = await requireUser();
    const b = await req.json();
    const status = String(b.status || "").trim();
    if (!["OPEN", "RESOLVED", "CANCELLED"].includes(status)) {
      throw new HttpError(400, "Invalid status");
    }
    const updated = await updateCaseStatus(
      params.id,
      status as EmergencyCase["status"],
      user.name
    );
    if (!updated) throw new HttpError(404, "Case not found");
    return json({ case: updated });
  });
}
