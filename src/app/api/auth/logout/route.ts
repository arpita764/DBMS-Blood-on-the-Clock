import { handleApi, json } from "@/lib/http";
import { SESSION_COOKIE } from "@/lib/session";

export async function POST() {
  return handleApi(async () => {
    const res = json({ ok: true });
    res.headers.set(
      "set-cookie",
      `${SESSION_COOKIE}=; HttpOnly; Path=/; Max-Age=0`
    );
    return res;
  });
}
