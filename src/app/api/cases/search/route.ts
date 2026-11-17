import { NextRequest } from "next/server";
import { handleApi, json, HttpError } from "@/lib/http";
import { requireUser } from "@/lib/auth";
import { searchCases } from "@/lib/vector";

export async function GET(req: NextRequest) {
  return handleApi(async () => {
    await requireUser();
    const q = new URL(req.url).searchParams.get("q") || "";
    if (!q.trim()) throw new HttpError(400, "Query parameter 'q' is required");
    return json(await searchCases(q, 8));
  });
}
