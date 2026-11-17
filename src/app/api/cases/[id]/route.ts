import { NextRequest } from "next/server";
import { handleApi, json, HttpError } from "@/lib/http";
import { requireUser } from "@/lib/auth";
import { getCase } from "@/lib/vector";

export async function GET(
  _req: NextRequest,
  { params }: { params: { id: string } }
) {
  return handleApi(async () => {
    await requireUser();
    const c = await getCase(params.id);
    if (!c) throw new HttpError(404, "Case not found");
    return json(c);
  });
}
