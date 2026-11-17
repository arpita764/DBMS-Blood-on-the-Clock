import { NextRequest } from "next/server";
import { handleApi, json, HttpError } from "@/lib/http";
import { requireUser } from "@/lib/auth";
import { addTimelineEvent } from "@/lib/vector";

export async function POST(
  req: NextRequest,
  { params }: { params: { id: string } }
) {
  return handleApi(async () => {
    const user = await requireUser();
    const b = await req.json();
    const event = String(b.event || "").trim();
    const note = String(b.note || "").trim();
    if (!event) throw new HttpError(400, "Event is required");
    const updated = await addTimelineEvent(params.id, {
      at: new Date().toISOString(),
      actor: user.name,
      event,
      note,
    });
    if (!updated) throw new HttpError(404, "Case not found");
    return json({ case: updated });
  });
}
