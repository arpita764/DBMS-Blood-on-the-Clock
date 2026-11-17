"use client";

import { useEffect, useMemo, useState } from "react";
import { apiFetch } from "@/lib/api-client";
import { Shell } from "@/components/Shell";
import { Card, Input, Select, Badge, Th, Td, EmptyState, Button } from "@/components/ui";
import { statusColor } from "@/lib/format";

interface Hospital {
  hospital_id: number;
  hospital_name: string;
  address: string | null;
  city: string;
  phone: string | null;
  hospital_type: string | null;
  status: string;
  relevance?: number;
}

export default function HospitalsPage() {
  const [rows, setRows] = useState<Hospital[]>([]);
  const [all, setAll] = useState<Hospital[]>([]);
  const [q, setQ] = useState("");
  const [city, setCity] = useState("");
  const [loading, setLoading] = useState(true);
  const [err, setErr] = useState("");
  const [searched, setSearched] = useState(false);

  useEffect(() => {
    apiFetch<Hospital[]>("/api/hospitals")
      .then((d) => {
        setAll(d);
        setRows(d);
      })
      .catch((e) => setErr(e instanceof Error ? e.message : "Failed to load"))
      .finally(() => setLoading(false));
  }, []);

  const cities = useMemo(
    () => Array.from(new Set(all.map((r) => r.city))).sort(),
    [all]
  );

  async function runSearch() {
    setLoading(true);
    setErr("");
    setSearched(true);
    try {
      const qs = new URLSearchParams();
      if (q.trim()) qs.set("q", q.trim());
      else if (city) qs.set("city", city);
      setRows(await apiFetch<Hospital[]>(`/api/hospitals?${qs}`));
    } catch (e) {
      setErr(e instanceof Error ? e.message : "Search failed");
    } finally {
      setLoading(false);
    }
  }

  function reset() {
    setQ("");
    setCity("");
    setSearched(false);
    setRows(all);
  }

  return (
    <Shell>
      <h1 className="mb-4 text-2xl font-bold text-gray-800">Hospitals</h1>
      {err && <div className="mb-3 rounded-lg bg-red-50 px-3 py-2 text-sm text-red-700">{err}</div>}
      <Card>
        <div className="mb-4 flex flex-wrap items-end gap-3">
          <div className="grow">
            <Input
              label="Full-text search"
              value={q}
              onChange={(e) => setQ(e.target.value)}
              placeholder="e.g. trauma blood delhi"
            />
          </div>
          <Select label="Or filter by city" value={city} onChange={(e) => setCity(e.target.value)} className="w-48">
            <option value="">All cities</option>
            {cities.map((c) => <option key={c} value={c}>{c}</option>)}
          </Select>
          <Button onClick={runSearch}>Search</Button>
          {searched && <Button variant="ghost" onClick={reset}>Reset</Button>}
        </div>
        <p className="mb-3 text-xs text-gray-400">
          {searched && q.trim()
            ? "Ranked by full-text relevance (MATCH … AGAINST)."
            : "Use the search box for full-text search across name, city and type."}
        </p>
        {loading ? (
          <div className="text-gray-400">Loading…</div>
        ) : rows.length === 0 ? (
          <EmptyState message="No hospitals found" />
        ) : (
          <table className="w-full">
            <thead>
              <tr>
                <Th>Hospital</Th><Th>Type</Th><Th>City</Th><Th>Phone</Th><Th>Status</Th>
                {searched && q.trim() && <Th>Relevance</Th>}
              </tr>
            </thead>
            <tbody>
              {rows.map((r) => (
                <tr key={r.hospital_id} className="border-b border-gray-50">
                  <Td className="font-medium">{r.hospital_name}</Td>
                  <Td>{r.hospital_type || "—"}</Td>
                  <Td>{r.city}</Td>
                  <Td>{r.phone || "—"}</Td>
                  <Td><Badge className={statusColor(r.status)}>{r.status}</Badge></Td>
                  {searched && q.trim() && (
                    <Td className="text-xs text-gray-400">
                      {r.relevance != null ? Number(r.relevance).toFixed(2) : "—"}
                    </Td>
                  )}
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </Card>
    </Shell>
  );
}
