"use client";

import { useEffect, useState } from "react";
import { apiFetch } from "@/lib/api-client";
import { Shell } from "@/components/Shell";
import { Card, StatCard, EmptyState, Badge, Th, Td } from "@/components/ui";
import { priorityColor } from "@/lib/format";

interface Stats {
  hospitalsActive: number;
  bloodRequestsOpen: number;
  resourceRequestsOpen: number;
  totalAvailableUnits: number;
  casesOpen: number;
  casesTotal: number;
  lowStock: { hospital_name: string; city: string; group_name: string; available_units: number; reserved_units: number }[];
  pendingByPriority: { priority: string; count: number }[];
}

export default function DashboardPage() {
  const [stats, setStats] = useState<Stats | null>(null);
  const [error, setError] = useState("");

  useEffect(() => {
    apiFetch<Stats>("/api/dashboard/stats")
      .then(setStats)
      .catch((e) => setError(e instanceof Error ? e.message : "Failed to load"));
  }, []);

  return (
    <Shell>
      <h1 className="mb-4 text-2xl font-bold text-gray-800">Dashboard</h1>
      {error && (
        <div className="mb-4 rounded-lg bg-red-50 px-3 py-2 text-sm text-red-700">
          {error}
        </div>
      )}
      {!stats ? (
        <div className="text-gray-400">Loading…</div>
      ) : (
        <div className="space-y-6">
          <div className="grid grid-cols-2 gap-4 md:grid-cols-5">
            <StatCard label="Active hospitals" value={stats.hospitalsActive} tone="blue" />
            <StatCard label="Open blood requests" value={stats.bloodRequestsOpen} tone="amber" />
            <StatCard label="Open resource requests" value={stats.resourceRequestsOpen} tone="amber" />
            <StatCard label="Total blood units" value={stats.totalAvailableUnits} tone="green" />
            <StatCard label="Open cases" value={stats.casesOpen} sub={`${stats.casesTotal} total`} tone="gray" />
          </div>

          <div className="grid gap-6 lg:grid-cols-2">
            <Card title="Low blood stock (available < 5 units)">
              {stats.lowStock.length === 0 ? (
                <EmptyState message="No low-stock items" />
              ) : (
                <table className="w-full">
                  <thead>
                    <tr>
                      <Th>Hospital</Th>
                      <Th>City</Th>
                      <Th>Group</Th>
                      <Th>Avail.</Th>
                      <Th>Resv.</Th>
                    </tr>
                  </thead>
                  <tbody>
                    {stats.lowStock.map((r, i) => (
                      <tr key={i} className="border-b border-gray-50">
                        <Td>{r.hospital_name}</Td>
                        <Td>{r.city}</Td>
                        <Td><Badge className="bg-gray-100">{r.group_name}</Badge></Td>
                        <Td className="font-semibold text-red-600">{r.available_units}</Td>
                        <Td>{r.reserved_units}</Td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              )}
            </Card>

            <Card title="Pending requests by priority">
              {stats.pendingByPriority.length === 0 ? (
                <EmptyState message="No pending requests" />
              ) : (
                <div className="space-y-3">
                  {stats.pendingByPriority.map((p) => (
                    <div key={p.priority} className="flex items-center justify-between">
                      <Badge className={priorityColor(p.priority)}>{p.priority}</Badge>
                      <span className="text-sm font-medium text-gray-700">{p.count} request(s)</span>
                    </div>
                  ))}
                </div>
              )}
            </Card>
          </div>
        </div>
      )}
    </Shell>
  );
}
