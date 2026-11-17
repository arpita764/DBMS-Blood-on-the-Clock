"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { apiFetch } from "@/lib/api-client";
import { Shell } from "@/components/Shell";
import { Card, Button, Input, Select, Badge, EmptyState } from "@/components/ui";
import { statusColor, priorityColor, formatDate } from "@/lib/format";

interface CaseDetail {
  caseId: string;
  title: string;
  narrative: string;
  caseType: string;
  severity: string;
  status: string;
  priorityLabel: string;
  bloodGroup: string | null;
  resourceType: string | null;
  patientAgeGroup: string;
  createdBy: number;
  createdByName: string;
  createdAt: string;
  updatedAt: string;
  hospitalIds: number[];
  hospitalNames: string[];
  tags: string[];
  linkedRequestIds: number[];
  timeline: { at: string; actor: string; event: string; note?: string }[];
}

function Row({ k, v }: { k: string; v: React.ReactNode }) {
  return (
    <div className="flex justify-between">
      <dt className="text-gray-400">{k}</dt>
      <dd className="font-medium text-gray-700">{v}</dd>
    </div>
  );
}

export default function CaseDetailPage() {
  const params = useParams();
  const id = params.id as string;
  const [c, setC] = useState<CaseDetail | null>(null);
  const [err, setErr] = useState("");
  const [msg, setMsg] = useState("");
  const [evEvent, setEvEvent] = useState("NOTE");
  const [evNote, setEvNote] = useState("");

  async function load() {
    setErr("");
    try {
      setC(await apiFetch<CaseDetail>(`/api/cases/${id}`));
    } catch (e) {
      setErr(e instanceof Error ? e.message : "Case not found");
    }
  }
  useEffect(() => {
    load();
  }, [id]);

  function flash(m: string) {
    setMsg(m);
    setTimeout(() => setMsg(""), 5000);
  }

  async function addEvent() {
    try {
      await apiFetch(`/api/cases/${id}/event`, {
        method: "POST",
        body: JSON.stringify({ event: evEvent, note: evNote }),
      });
      flash("Event added");
      setEvNote("");
      load();
    } catch (e) {
      flash(e instanceof Error ? e.message : "Failed");
    }
  }

  async function setStatus(s: string) {
    try {
      await apiFetch(`/api/cases/${id}/status`, {
        method: "POST",
        body: JSON.stringify({ status: s }),
      });
      flash(`Status set to ${s}`);
      load();
    } catch (e) {
      flash(e instanceof Error ? e.message : "Failed");
    }
  }

  return (
    <Shell>
      {err ? (
        <div className="rounded-lg bg-red-50 px-3 py-2 text-sm text-red-700">{err}</div>
      ) : !c ? (
        <div className="text-gray-400">Loading…</div>
      ) : (
        <>
          <div className="mb-4 flex items-start justify-between">
            <div>
              <div className="flex items-center gap-2">
                <h1 className="text-2xl font-bold text-gray-800">{c.title}</h1>
                <Badge className={statusColor(c.status)}>{c.status}</Badge>
              </div>
              <div className="mt-1 text-xs text-gray-400">
                {c.caseId} · created {formatDate(c.createdAt)} by {c.createdByName}
              </div>
            </div>
            <div className="flex gap-2">
              {c.status !== "RESOLVED" && (
                <Button variant="secondary" onClick={() => setStatus("RESOLVED")}>Resolve</Button>
              )}
              {c.status !== "CANCELLED" && (
                <Button variant="danger" onClick={() => setStatus("CANCELLED")}>Cancel</Button>
              )}
              {c.status !== "OPEN" && (
                <Button variant="ghost" onClick={() => setStatus("OPEN")}>Reopen</Button>
              )}
            </div>
          </div>
          {msg && <div className="mb-3 rounded-lg bg-green-50 px-3 py-2 text-sm text-green-700">{msg}</div>}

          <div className="grid gap-6 lg:grid-cols-3">
            <div className="space-y-6 lg:col-span-2">
              <Card title="Narrative">
                <p className="whitespace-pre-wrap text-sm text-gray-700">{c.narrative}</p>
              </Card>
              <Card title={`Timeline (${c.timeline.length})`}>
                {c.timeline.length === 0 ? (
                  <EmptyState message="No events" />
                ) : (
                  <ol className="relative space-y-3 border-l border-gray-200 pl-4">
                    {c.timeline.map((t, i) => (
                      <li key={i}>
                        <div className="text-xs text-gray-400">{formatDate(t.at)} · {t.actor}</div>
                        <div className="text-sm font-medium text-gray-700">{t.event}</div>
                        {t.note && <div className="text-sm text-gray-500">{t.note}</div>}
                      </li>
                    ))}
                  </ol>
                )}
                <div className="mt-4 flex flex-wrap items-end gap-2 border-t border-gray-100 pt-3">
                  <Select label="Event" value={evEvent} onChange={(e) => setEvEvent(e.target.value)} className="w-44">
                    <option>NOTE</option>
                    <option>BLOOD_RESERVED</option>
                    <option>BLOOD_FULFILLED</option>
                    <option>RESOURCE_ALLOCATED</option>
                    <option>PATIENT_UPDATE</option>
                    <option>ESCALATION</option>
                  </Select>
                  <Input label="Note" className="grow" value={evNote} onChange={(e) => setEvNote(e.target.value)} placeholder="Optional details" />
                  <Button onClick={addEvent}>Add event</Button>
                </div>
              </Card>
            </div>

            <div className="space-y-6">
              <Card title="Details">
                <dl className="space-y-2 text-sm">
                  <Row k="Case type" v={<Badge className="bg-gray-100">{c.caseType}</Badge>} />
                  <Row k="Severity" v={<Badge className={priorityColor(c.severity)}>{c.severity}</Badge>} />
                  <Row k="Priority" v={c.priorityLabel || "—"} />
                  <Row k="Blood group" v={c.bloodGroup || "—"} />
                  <Row k="Resource type" v={c.resourceType || "—"} />
                  <Row k="Patient age" v={c.patientAgeGroup || "—"} />
                  <Row k="Updated" v={formatDate(c.updatedAt)} />
                </dl>
              </Card>
              <Card title="Hospitals">
                {c.hospitalNames.length ? (
                  <div className="flex flex-wrap gap-1.5">
                    {c.hospitalNames.map((h, i) => <Badge key={i} className="bg-gray-100">{h}</Badge>)}
                  </div>
                ) : <EmptyState message="None" />}
              </Card>
              <Card title="Tags">
                {c.tags.length ? (
                  <div className="flex flex-wrap gap-1.5">
                    {c.tags.map((t, i) => <Badge key={i} className="border-purple-200 bg-purple-100 text-purple-700">{t}</Badge>)}
                  </div>
                ) : <EmptyState message="None" />}
              </Card>
              <Card title="Linked requests">
                {c.linkedRequestIds.length ? (
                  <div className="flex flex-wrap gap-1.5">
                    {c.linkedRequestIds.map((r, i) => <Badge key={i} className="bg-gray-100">#{r}</Badge>)}
                  </div>
                ) : <EmptyState message="None" />}
              </Card>
            </div>
          </div>
        </>
      )}
    </Shell>
  );
}
