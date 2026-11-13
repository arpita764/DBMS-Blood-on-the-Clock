"use client";

import { Fragment, useEffect, useState } from "react";
import { apiFetch } from "@/lib/api-client";
import { Shell } from "@/components/Shell";
import { Card, Button, Input, Select, Badge, Th, Td, EmptyState, Modal } from "@/components/ui";
import { statusColor, priorityColor, formatDate } from "@/lib/format";

interface Req {
  request_id: number;
  hospital_name: string;
  city: string;
  group_name: string;
  quantity_required: number;
  priority: string;
  status: string;
  created_at: string;
  required_by: string;
}
interface Resv {
  reservation_id: number;
  request_id: number;
  supplier_hospital: string;
  group_name: string;
  units_reserved: number;
  status: string;
  reserved_by_name: string | null;
  reserved_at: string;
}
interface Hosp { hospital_id: number; hospital_name: string; city: string; status: string }
interface Group { blood_group_id: number; group_name: string }

export default function BloodRequestsPage() {
  const [reqs, setReqs] = useState<Req[]>([]);
  const [resvs, setResvs] = useState<Resv[]>([]);
  const [hospitals, setHospitals] = useState<Hosp[]>([]);
  const [groups, setGroups] = useState<Group[]>([]);
  const [err, setErr] = useState("");
  const [msg, setMsg] = useState("");
  const [openId, setOpenId] = useState<number | null>(null);
  const [showNew, setShowNew] = useState(false);

  const [fHosp, setFHosp] = useState("");
  const [fGroup, setFGroup] = useState("");
  const [fQty, setFQty] = useState(1);
  const [fPrio, setFPrio] = useState("MEDIUM");
  const [fBy, setFBy] = useState("");
  const [rSup, setRSup] = useState<Record<number, string>>({});
  const [rUnits, setRUnits] = useState<Record<number, number>>({});

  async function load() {
    setErr("");
    try {
      const [r, h, g, rv] = await Promise.all([
        apiFetch<Req[]>("/api/blood/requests"),
        apiFetch<Hosp[]>("/api/hospitals"),
        apiFetch<Group[]>("/api/blood/groups"),
        apiFetch<Resv[]>("/api/blood/reservations"),
      ]);
      setReqs(r);
      setHospitals(h);
      setGroups(g);
      setResvs(rv);
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
      const out = await apiFetch<{ message: string }>("/api/blood/requests", {
        method: "POST",
        body: JSON.stringify({
          hospital_id: fHosp,
          blood_group_id: fGroup,
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

  async function reserve(rid: number) {
    try {
      const out = await apiFetch<{ message: string }>("/api/blood/reservations", {
        method: "POST",
        body: JSON.stringify({
          request_id: rid,
          supplier_hospital_id: rSup[rid],
          units: rUnits[rid] ?? 1,
        }),
      });
      flash(out.message);
      load();
    } catch (e) {
      flash(e instanceof Error ? e.message : "Failed");
    }
  }

  async function act(path: string) {
    try {
      const out = await apiFetch<{ message: string }>(path, { method: "POST" });
      flash(out.message);
      load();
    } catch (e) {
      flash(e instanceof Error ? e.message : "Failed");
    }
  }

  return (
    <Shell>
      <div className="mb-4 flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-800">Blood Requests</h1>
        <Button onClick={() => setShowNew(true)}>+ New Request</Button>
      </div>
      {err && <div className="mb-3 rounded-lg bg-red-50 px-3 py-2 text-sm text-red-700">{err}</div>}
      {msg && <div className="mb-3 rounded-lg bg-green-50 px-3 py-2 text-sm text-green-700">{msg}</div>}

      <Card>
        {reqs.length === 0 ? (
          <EmptyState message="No blood requests" />
        ) : (
          <table className="w-full">
            <thead>
              <tr>
                <Th>ID</Th><Th>Hospital</Th><Th>Group</Th><Th>Qty</Th>
                <Th>Priority</Th><Th>Status</Th><Th>Required by</Th><Th></Th>
              </tr>
            </thead>
            <tbody>
              {reqs.map((r) => (
                <Fragment key={r.request_id}>
                  <tr
                    className="cursor-pointer border-b border-gray-50 hover:bg-gray-50"
                    onClick={() => setOpenId(openId === r.request_id ? null : r.request_id)}
                  >
                    <Td>#{r.request_id}</Td>
                    <Td>{r.hospital_name}</Td>
                    <Td><Badge className="bg-gray-100">{r.group_name}</Badge></Td>
                    <Td className="font-semibold">{r.quantity_required}</Td>
                    <Td><Badge className={priorityColor(r.priority)}>{r.priority}</Badge></Td>
                    <Td><Badge className={statusColor(r.status)}>{r.status}</Badge></Td>
                    <Td>{formatDate(r.required_by)}</Td>
                    <Td className="text-xs text-gray-400">{openId === r.request_id ? "▲" : "▼"}</Td>
                  </tr>
                  {openId === r.request_id && (
                    <tr className="bg-gray-50/60">
                      <td colSpan={8} className="p-4">
                        <div className="mb-3 flex flex-wrap items-center gap-2">
                          <span className="text-sm font-medium text-gray-600">Reserve from:</span>
                          <select
                            className="rounded border border-gray-300 px-2 py-1 text-sm"
                            value={rSup[r.request_id] ?? ""}
                            onChange={(e) => setRSup({ ...rSup, [r.request_id]: e.target.value })}
                          >
                            <option value="">Supplier hospital…</option>
                            {hospitals
                              .filter((h) => h.status === "ACTIVE" && h.hospital_name !== r.hospital_name)
                              .map((h) => (
                                <option key={h.hospital_id} value={h.hospital_id}>
                                  {h.hospital_name} ({h.city})
                                </option>
                              ))}
                          </select>
                          <input
                            type="number" min={1}
                            className="w-20 rounded border border-gray-300 px-2 py-1 text-sm"
                            value={rUnits[r.request_id] ?? 1}
                            onChange={(e) => setRUnits({ ...rUnits, [r.request_id]: Number(e.target.value) })}
                          />
                          <Button variant="secondary" onClick={() => reserve(r.request_id)} disabled={!rSup[r.request_id]}>
                            Reserve
                          </Button>
                          {(r.status === "PENDING" || r.status === "RESERVED") && (
                            <Button variant="danger" onClick={() => act(`/api/blood/requests/${r.request_id}/cancel`)}>
                              Cancel request
                            </Button>
                          )}
                        </div>
                        <div className="mb-1 text-xs font-medium uppercase tracking-wide text-gray-400">
                          Reservations
                        </div>
                        {resvs.filter((rv) => rv.request_id === r.request_id).length === 0 ? (
                          <div className="py-2 text-sm text-gray-400">No reservations yet</div>
                        ) : (
                          <table className="w-full">
                            <thead>
                              <tr>
                                <Th>Supplier</Th><Th>Group</Th><Th>Units</Th>
                                <Th>Status</Th><Th>By</Th><Th>At</Th><Th>Actions</Th>
                              </tr>
                            </thead>
                            <tbody>
                              {resvs
                                .filter((rv) => rv.request_id === r.request_id)
                                .map((rv) => (
                                  <tr key={rv.reservation_id} className="border-b border-gray-100">
                                    <Td>{rv.supplier_hospital}</Td>
                                    <Td>{rv.group_name}</Td>
                                    <Td>{rv.units_reserved}</Td>
                                    <Td><Badge className={statusColor(rv.status)}>{rv.status}</Badge></Td>
                                    <Td>{rv.reserved_by_name || "—"}</Td>
                                    <Td>{formatDate(rv.reserved_at)}</Td>
                                    <Td className="space-x-3">
                                      {rv.status === "RESERVED" && (
                                        <>
                                          <button className="text-xs font-medium text-green-700 hover:underline" onClick={() => act(`/api/blood/reservations/${rv.reservation_id}/fulfill`)}>
                                            Fulfill
                                          </button>
                                          <button className="text-xs font-medium text-red-600 hover:underline" onClick={() => act(`/api/blood/reservations/${rv.reservation_id}/release`)}>
                                            Release
                                          </button>
                                        </>
                                      )}
                                    </Td>
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

      <Modal open={showNew} onClose={() => setShowNew(false)} title="New emergency blood request">
        <div className="space-y-3">
          <Select label="Hospital" value={fHosp} onChange={(e) => setFHosp(e.target.value)}>
            <option value="">Select hospital…</option>
            {hospitals.map((h) => (
              <option key={h.hospital_id} value={h.hospital_id}>{h.hospital_name} ({h.city})</option>
            ))}
          </Select>
          <Select label="Blood group" value={fGroup} onChange={(e) => setFGroup(e.target.value)}>
            <option value="">Select group…</option>
            {groups.map((g) => (
              <option key={g.blood_group_id} value={g.blood_group_id}>{g.group_name}</option>
            ))}
          </Select>
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
