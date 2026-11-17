import { NextRequest } from "next/server";
import { handleApi, json, HttpError } from "@/lib/http";
import { requireUser } from "@/lib/auth";
import { cancelResourceRequest } from "@/lib/procedures";

export async function POST(
  _req: NextRequest,
  { params }: { params: { id: string } }
) {
  return handleApi(async () => {
    const user = await requireUser();
    const out = await cancelResourceRequest(Number(params.id), user.userId);
    const msg = String(out.message ?? "");
    if (msg.startsWith("ERROR")) throw new HttpError(400, msg);
    return json(out);
  });
}
