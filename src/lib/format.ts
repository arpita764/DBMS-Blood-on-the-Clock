// Pure formatting helpers shared between client and server. No server imports.

export function formatDate(iso?: string | null): string {
  if (!iso) return "—";
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return iso;
  return d.toLocaleString(undefined, {
    year: "numeric",
    month: "short",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
  });
}

export function formatDateShort(iso?: string | null): string {
  if (!iso) return "—";
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return iso;
  return d.toLocaleDateString(undefined, {
    year: "numeric",
    month: "short",
    day: "2-digit",
  });
}

export function priorityColor(p?: string): string {
  switch (p) {
    case "CRITICAL":
      return "bg-red-100 text-red-700 border-red-200";
    case "HIGH":
      return "bg-orange-100 text-orange-700 border-orange-200";
    case "MEDIUM":
      return "bg-yellow-100 text-yellow-700 border-yellow-200";
    case "LOW":
      return "bg-green-100 text-green-700 border-green-200";
    default:
      return "bg-gray-100 text-gray-700 border-gray-200";
  }
}

export function statusColor(s?: string): string {
  const map: Record<string, string> = {
    PENDING: "bg-yellow-100 text-yellow-700 border-yellow-200",
    RESERVED: "bg-blue-100 text-blue-700 border-blue-200",
    FULFILLED: "bg-green-100 text-green-700 border-green-200",
    CANCELLED: "bg-gray-100 text-gray-500 border-gray-200",
    PARTIALLY_FULFILLED: "bg-blue-100 text-blue-700 border-blue-200",
    ALLOCATED: "bg-green-100 text-green-700 border-green-200",
    RELEASED: "bg-gray-100 text-gray-500 border-gray-200",
    AVAILABLE: "bg-green-100 text-green-700 border-green-200",
    UNAVAILABLE: "bg-red-100 text-red-700 border-red-200",
    ACTIVE: "bg-green-100 text-green-700 border-green-200",
    INACTIVE: "bg-gray-100 text-gray-500 border-gray-200",
    OPEN: "bg-yellow-100 text-yellow-700 border-yellow-200",
    RESOLVED: "bg-green-100 text-green-700 border-green-200",
  };
  return map[s ?? ""] || "bg-gray-100 text-gray-700 border-gray-200";
}

export function similarityPct(score: number): string {
  return `${Math.max(0, Math.min(100, Math.round(score * 100)))}%`;
}
