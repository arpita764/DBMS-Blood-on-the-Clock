"use client";

import { Fragment, useEffect, useState } from "react";
import { apiFetch } from "@/lib/api-client";
import { Shell } from "@/components/Shell";
import { Card, Button, Input, Select, Badge, Th, Td, EmptyState, Modal } from "@/components/ui";
import { statusColor, priorityColor, formatDate } from "@/lib/format";

interface Req {
  resource_request_id: number;
  hospital_name: string;
  city: string;
  resource_type: string;
  quantity_required: number;
  priority: string;
  status: string;
  required_by: string;
}
interface Alloc {
  allocation_id: number;
  resource_request_id: number;
  resource_name: string;
  supplier_hospital: string;
  quantity_allocated: number;
  status: string;
  allocated_by_name: string | null;
  allocated_at: string;
  released_at: string | null;
}
interface Hosp { hospital_id: number; hospital_name: string; city: string; status: string }
interface ResRow { resource_id: number; hospital_name: string; resource_name: string; resource_type: string; available_quantity: number; hospital_id: number }

export default function ResourceRequestsPage() {
  const [reqs, setReqs] = useState<Req[]>([]);
  const [allocs, setAllocs] = useState<Alloc[]>([]);
  const [hospitals, setHospitals] = useState<Hosp[]>([]);
  const [resources, setResources] = useState<ResRow[]>([]);
  const [err, setErr] = useState("");
  const [msg, setMsg] = useState("");
  const [openId, setOpenId] = useState<number | null>(null);
  const [showNew, setShowNew] = useState(false);

  const [fHosp, setFHosp] = useState("");
  const [fType, setFType] = useState("ICU Bed");
  const [fQty, setFQty] = useState(1);
  const [fPrio, setFPrio] = useState("MEDIUM");
  const [fBy, setFBy] = useState("");
  const [aRes, setARes] = useState<Record<number, string>>({});
  const [aUnits, setAUnits] = useState<Record<number, number>>({});

  async function load() {
    setErr("");
    try {
      const [r, h, rv, al] = await Promise.all([
        apiFetch<Req[]>("/api/resources/requests"),
        apiFetch<Hosp[]>("/api/hospitals"),
        apiFetch<ResRow[]>("/api/resources/inventory"),
        apiFetch<Alloc[]>("/api/resources/allocations"),
      ]);
      setReqs(r);
      setHospitals(h);
      setResources(rv);
      setAllocs(al);
    } catch (e) {
      setErr(e instanceof Error ? e.message : "Failed to load");
    }
  }
  useEffect(() => {
    load();
  }, []);

  function flash(m: string) {
    setMsg(m);
    setTimeout(() => setMsg(""), 5000);
  }

  async function create() {
    try {
      const out = await apiFetch<{ message: string }>("/api/resources/requests", {
        method: "POST",
        body: JSON.stringify({
          hospital_id: fHosp,
          resource_type: fType,
          quantity_required: fQty,
          priority: fPrio,
          required_by: fBy,
        }),
      });
      flash(out.message);
      setShowNew(false);
      load();
    } catch (e) {
      flash(e instanceof Error ? e.message : "Failed");
    }
  }

  async function allocate(rid: number, rtype: string, requesterHospital: string) {
    const resId = aRes[rid];
    if (!resId) return flash("Select a supplier resource first");
    try {
      const out = await apiFetch<{ message: string }>(
        `/api/resources/requests/${rid}/allocate`,
        { method: "POST", body: JSON.stringify({ resource_id: resId, units: aUnits[rid] ?? 1 }) }
      );
      flash(out.message);
      load();
    } catch (e) {
      flash(e instanceof Error ? e.message : "Failed");
    }
  }

  async function cancel(rid: number) {
    try {
      const out = await apiFetch<{ message: string }>(`/api/resources/requests/${rid}/cancel`, {
        method: "POST",
      });
      flash(out.message);
      load();
    } catch (e) {
      flash(e instanceof Error ? e.message : "Failed");
    }
  }

  return (
    <Shell>
      <div className="mb-4 flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-800">Resource Requests</h1>
        <Button onClick={() => setShowNew(true)}>+ New Request</Button>
      </div>
      {err && <div className="mb-3 rounded-lg bg-red-50 px-3 py-2 text-sm text-red-700">{err}</div>}
      {msg && <div className="mb-3 rounded-lg bg-green-50 px-3 py-2 text-sm text-green-700">{msg}</div>}

      <Card>
        {reqs.length === 0 ? (
          <EmptyState message="No resource requests" />
        ) : (
          <table className="w-full">
            <thead>
              <tr>
                <Th>ID</Th><Th>Hospital</Th><Th>Type</Th><Th>Qty</Th>
                <Th>Priority</Th><Th>Status</Th><Th>Required by</Th><Th></Th>
              </tr>
            </thead>
            <tbody>
              {reqs.map((r) => (
                <Fragment key={r.resource_request_id}>
                  <tr
                    className="cursor-pointer border-b border-gray-50 hover:bg-gray-50"
                    onClick={() => setOpenId(openId === r.resource_request_id ? null : r.resource_request_id)}
                  >
                    <Td>#{r.resource_request_id}</Td>
                    <Td>{r.hospital_name}</Td>
                    <Td><Badge className="bg-gray-100">{r.resource_type}</Badge></Td>
                    <Td className="font-semibold">{r.quantity_required}</Td>
                    <Td><Badge className={priorityColor(r.priority)}>{r.priority}</Badge></Td>
                    <Td><Badge className={statusColor(r.status)}>{r.status}</Badge></Td>
                    <Td>{formatDate(r.required_by)}</Td>
                    <Td className="text-xs text-gray-400">{openId === r.resource_request_id ? "▲" : "▼"}</Td>
                  </tr>
                  {openId === r.resource_request_id && (
                    <tr className="bg-gray-50/60">
                      <td colSpan={8} className="p-4">
                        <div className="mb-3 flex flex-wrap items-center gap-2">
                          <span className="text-sm font-medium text-gray-600">Allocate from:</span>
                          <select
                            className="rounded border border-gray-300 px-2 py-1 text-sm"
                            value={aRes[r.resource_request_id] ?? ""}
                            onChange={(e) => setARes({ ...aRes, [r.resource_request_id]: e.target.value })}
                          >
                            <option value="">Supplier resource…</option>
                            {resources
                              .filter((res) => res.resource_type === r.resource_type && res.available_quantity > 0 && res.hospital_name !== r.hospital_name)
                              .map((res) => (
                                <option key={res.resource_id} value={res.resource_id}>
                                  {res.resource_name} — {res.hospital_name} ({res.available_quantity} avail)
                                </option>
                              ))}
                          </select>
                          <input
                            type="number" min={1}
                            className="w-20 rounded border border-gray-300 px-2 py-1 text-sm"
                            value={aUnits[r.resource_request_id] ?? 1}
                            onChange={(e) => setAUnits({ ...aUnits, [r.resource_request_id]: Number(e.target.value) })}
                          />
                          <Button variant="secondary" onClick={() => allocate(r.resource_request_id, r.resource_type, r.hospital_name)} disabled={!aRes[r.resource_request_id]}>
                            Allocate
                          </Button>
                          {r.status !== "FULFILLED" && r.status !== "CANCELLED" && (
                            <Button variant="danger" onClick={() => cancel(r.resource_request_id)}>Cancel request</Button>
                          )}
                        </div>
                        <div className="mb-1 text-xs font-medium uppercase tracking-wide text-gray-400">Allocations</div>
                        {allocs.filter((a) => a.resource_request_id === r.resource_request_id).length === 0 ? (
                          <div className="py-2 text-sm text-gray-400">No allocations yet</div>
                        ) : (
                          <table className="w-full">
                            <thead>
                              <tr><Th>Resource</Th><Th>Supplier</Th><Th>Units</Th><Th>Status</Th><Th>By</Th><Th>At</Th></tr>
                            </thead>
                            <tbody>
                              {allocs.filter((a) => a.resource_request_id === r.resource_request_id).map((a) => (
                                <tr key={a.allocation_id} className="border-b border-gray-100">
                                  <Td>{a.resource_name}</Td>
                                  <Td>{a.supplier_hospital}</Td>
                                  <Td>{a.quantity_allocated}</Td>
                                  <Td><Badge className={statusColor(a.status)}>{a.status}</Badge></Td>
                                  <Td>{a.allocated_by_name || "—"}</Td>
                                  <Td>{formatDate(a.allocated_at)}</Td>
                                </tr>
                              ))}
                            </tbody>
                          </table>
                        )}
                      </td>
                    </tr>
                  )}
                </Fragment>
              ))}
            </tbody>
          </table>
        )}
      </Card>

      <Modal open={showNew} onClose={() => setShowNew(false)} title="New emergency resource request">
        <div className="space-y-3">
          <Select label="Hospital" value={fHosp} onChange={(e) => setFHosp(e.target.value)}>
            <option value="">Select hospital…</option>
            {hospitals.map((h) => (
              <option key={h.hospital_id} value={h.hospital_id}>{h.hospital_name} ({h.city})</option>
            ))}
          </Select>
          <Input label="Resource type" value={fType} onChange={(e) => setFType(e.target.value)} placeholder="ICU Bed, Ventilator, Ambulance…" />
          <div className="grid grid-cols-2 gap-3">
            <Input label="Quantity" type="number" min={1} value={fQty} onChange={(e) => setFQty(Number(e.target.value))} />
            <Select label="Priority" value={fPrio} onChange={(e) => setFPrio(e.target.value)}>
              <option>CRITICAL</option><option>HIGH</option><option>MEDIUM</option><option>LOW</option>
            </Select>
          </div>
          <Input label="Required by" type="datetime-local" value={fBy} onChange={(e) => setFBy(e.target.value)} />
          <Button className="w-full" onClick={create}>Create request</Button>
        </div>
      </Modal>
    </Shell>
  );
}
