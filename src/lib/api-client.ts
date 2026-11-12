// Client-side fetch helper used by page components. Contains no server imports.

export async function apiFetch<T>(
  path: string,
  opts?: RequestInit
): Promise<T> {
  const headers: Record<string, string> = { Accept: "application/json" };
  if (opts?.body) headers["Content-Type"] = "application/json";
  const res = await fetch(path, {
    ...opts,
    headers: { ...headers, ...(opts?.headers as Record<string, string>) },
  });
  const text = await res.text();
  const data = text ? JSON.parse(text) : null;
  if (!res.ok) {
    throw new Error(
      (data && (data as { error?: string }).error) ||
        `Request failed (${res.status})`
    );
  }
  return data as T;
}
