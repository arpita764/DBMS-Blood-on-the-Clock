import "server-only";

export class HttpError extends Error {
  status: number;
  constructor(status: number, message: string) {
    super(message);
    this.status = status;
  }
}

export function json(data: unknown, status = 200): Response {
  return Response.json(data, { status });
}

/** Wrap a route handler so thrown HttpErrors map to proper status codes. */
export function handleApi(
  handler: () => Promise<Response>
): Promise<Response> {
  return handler().catch((e: unknown) => {
    if (e instanceof HttpError) return json({ error: e.message }, e.status);
    console.error("API error:", e);
    return json({ error: "Internal server error" }, 500);
  });
}
