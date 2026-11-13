import { handleApi, json } from "@/lib/http";
import { getCurrentUser } from "@/lib/auth";

export async function GET() {
  return handleApi(async () => json({ user: await getCurrentUser() }));
}
