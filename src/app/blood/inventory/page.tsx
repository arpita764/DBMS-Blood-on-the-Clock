"use client";

import { useEffect, useMemo, useState } from "react";
import { apiFetch } from "@/lib/api-client";
import { Shell } from "@/components/Shell";
import { Card, Select, Badge, Th, Td, EmptyState } from "@/components/ui";

interface Row {
  hospital_id: number;
  hospital_name: string;
  city: string;
  blood_group: string;
  available_units: number;
  reserved_units: number;
  last_updated: string;
  hospital_status: string;
}

export default function BloodInventoryPage() {
  const [rows, setRows] = useState<Row[]>([]);
  const [city, setCity] = useState("");
  const [group, setGroup] = useState("");
  const [loading, setLoading] = useState(true);
  const [err, setErr] = useState("");

  useEffect(() => {
    apiFetch<Row[]>("/api/blood/inventory")
      .then(setRows)
      .catch((e) => setErr(e instanceof Error ? e.message : "Failed to load"))
      .finally(() => setLoading(false));
  }, []);

  const cities = useMemo(
    () => Array.from(new Set(rows.map((r) => r.city))).sort(),
    [rows]
  );
  const groups = useMemo(
    () => Array.from(new Set(rows.map((r) => r.blood_group))),
    [rows]
  );
  const filtered = rows.filter(
    (r) =>
      (!city || r.city === city) && (!group || r.blood_group === group)
  );

  return (
    <Shell>
      <h1 className="mb-4 text-2xl font-bold text-gray-800">Blood Inventory</h1>
      {err && (
        <div className="mb-3 rounded-lg bg-red-50 px-3 py-2 text-sm text-red-700">
          {err}
        </div>
      )}
      <Card>
        <div className="mb-4 flex flex-wrap gap-3">
          <Select label="City" value={city} onChange={(e) => setCity(e.target.value)} className="w-48">
            <option value="">All cities</option>
            {cities.map((c) => (
              <option key={c} value={c}>{c}</option>
            ))}
          </Select>
          <Select label="Blood group" value={group} onChange={(e) => setGroup(e.target.value)} className="w-40">
            <option value="">All groups</option>
            {groups.map((g) => (
              <option key={g} value={g}>{g}</option>
            ))}
          </Select>
        </div>
        {loading ? (
          <div className="text-gray-400">Loading…</div>
        ) : filtered.length === 0 ? (
          <EmptyState message="No inventory matches the filters" />
        ) : (
          <table className="w-full">
            <thead>
              <tr>
                <Th>Hospital</Th>
                <Th>City</Th>
                <Th>Group</Th>
                <Th>Available</Th>
                <Th>Reserved</Th>
                <Th>Updated</Th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((r, i) => (
                <tr key={i} className="border-b border-gray-50">
                  <Td>{r.hospital_name}</Td>
                  <Td>{r.city}</Td>
                  <Td><Badge className="bg-gray-100">{r.blood_group}</Badge></Td>
                  <Td className={r.available_units < 5 ? "font-semibold text-red-600" : "font-semibold"}>{r.available_units}</Td>
                  <Td>{r.reserved_units}</Td>
                  <Td className="text-xs text-gray-400">{new Date(r.last_updated).toLocaleString()}</Td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </Card>
    </Shell>
  );
}
