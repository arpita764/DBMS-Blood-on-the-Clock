import { NextRequest } from "next/server";
import { handleApi, json, HttpError } from "@/lib/http";
import { requireUser } from "@/lib/auth";
import { allocateResource } from "@/lib/procedures";

export async function POST(
  req: NextRequest,
  { params }: { params: { id: string } }
) {
  return handleApi(async () => {
    const user = await requireUser();
    const b = await req.json();
    const out = await allocateResource(
      Number(params.id),
      Number(b.resource_id),
      Number(b.units),
      user.userId
    );
    const msg = String(out.message ?? "");
    if (msg.startsWith("ERROR")) throw new HttpError(400, msg);
    return json(out);
  });
}
