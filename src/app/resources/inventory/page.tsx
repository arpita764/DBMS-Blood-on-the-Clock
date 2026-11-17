"use client";

import { useEffect, useMemo, useState } from "react";
import { apiFetch } from "@/lib/api-client";
import { Shell } from "@/components/Shell";
import { Card, Select, Badge, Th, Td, EmptyState } from "@/components/ui";
import { statusColor } from "@/lib/format";

interface Row {
  resource_id: number;
  hospital_name: string;
  city: string;
  resource_name: string;
  resource_type: string;
  total_quantity: number;
  available_quantity: number;
  status: string;
}

export default function ResourceInventoryPage() {
  const [rows, setRows] = useState<Row[]>([]);
  const [city, setCity] = useState("");
  const [type, setType] = useState("");
  const [loading, setLoading] = useState(true);
  const [err, setErr] = useState("");

  useEffect(() => {
    apiFetch<Row[]>("/api/resources/inventory")
      .then(setRows)
      .catch((e) => setErr(e instanceof Error ? e.message : "Failed to load"))
      .finally(() => setLoading(false));
  }, []);

  const cities = useMemo(
    () => Array.from(new Set(rows.map((r) => r.city))).sort(),
    [rows]
  );
  const types = useMemo(
    () => Array.from(new Set(rows.map((r) => r.resource_type))).sort(),
    [rows]
  );
  const filtered = rows.filter(
    (r) => (!city || r.city === city) && (!type || r.resource_type === type)
  );

  return (
    <Shell>
      <h1 className="mb-4 text-2xl font-bold text-gray-800">Resource Inventory</h1>
      {err && <div className="mb-3 rounded-lg bg-red-50 px-3 py-2 text-sm text-red-700">{err}</div>}
      <Card>
        <div className="mb-4 flex flex-wrap gap-3">
          <Select label="City" value={city} onChange={(e) => setCity(e.target.value)} className="w-48">
            <option value="">All cities</option>
            {cities.map((c) => <option key={c} value={c}>{c}</option>)}
          </Select>
          <Select label="Resource type" value={type} onChange={(e) => setType(e.target.value)} className="w-48">
            <option value="">All types</option>
            {types.map((t) => <option key={t} value={t}>{t}</option>)}
          </Select>
        </div>
        {loading ? (
          <div className="text-gray-400">Loading…</div>
        ) : filtered.length === 0 ? (
          <EmptyState message="No resources match the filters" />
        ) : (
          <table className="w-full">
            <thead>
              <tr>
                <Th>Resource</Th><Th>Type</Th><Th>Hospital</Th><Th>City</Th>
                <Th>Available</Th><Th>Total</Th><Th>Status</Th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((r) => (
                <tr key={r.resource_id} className="border-b border-gray-50">
                  <Td className="font-medium">{r.resource_name}</Td>
                  <Td><Badge className="bg-gray-100">{r.resource_type}</Badge></Td>
                  <Td>{r.hospital_name}</Td>
                  <Td>{r.city}</Td>
                  <Td className={r.available_quantity === 0 ? "font-semibold text-red-600" : "font-semibold"}>{r.available_quantity}</Td>
                  <Td>{r.total_quantity}</Td>
                  <Td><Badge className={statusColor(r.status)}>{r.status}</Badge></Td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </Card>
    </Shell>
  );
}
