import { handleApi, json } from "@/lib/http";
import { requireUser } from "@/lib/auth";
import { caseStats } from "@/lib/vector";

export async function GET() {
  return handleApi(async () => {
    await requireUser();
    return json(await caseStats());
  });
}
