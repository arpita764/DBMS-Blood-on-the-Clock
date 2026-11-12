"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { apiFetch } from "@/lib/api-client";
import { Shell } from "@/components/Shell";
import { Card, Button, Input, Select, Badge, EmptyState, Modal } from "@/components/ui";
import { statusColor, priorityColor, similarityPct, formatDate } from "@/lib/format";

interface CaseItem {
  caseId: string;
  title: string;
  narrative: string;
  caseType: string;
  severity: string;
  status: string;
  tags: string[];
  hospitalNames: string[];
  bloodGroup: string | null;
  resourceType: string | null;
  createdByName: string;
  createdAt: string;
}
interface SearchResult {
  case: CaseItem;
  score: number;
}

export default function CasesPage() {
  const [cases, setCases] = useState<CaseItem[]>([]);
  const [results, setResults] = useState<SearchResult[] | null>(null);
  const [q, setQ] = useState("");
  const [err, setErr] = useState("");
  const [msg, setMsg] = useState("");
  const [showNew, setShowNew] = useState(false);
  const [searched, setSearched] = useState(false);

  const [fTitle, setFTitle] = useState("");
  const [fNarr, setFNarr] = useState("");
  const [fType, setFType] = useState("BLOOD");
  const [fSev, setFSev] = useState("HIGH");
  const [fPrio, setFPrio] = useState("");
  const [fBlood, setFBlood] = useState("");
  const [fRes, setFRes] = useState("");
  const [fAge, setFAge] = useState("adult");
  const [fTags, setFTags] = useState("");
  const [fHosp, setFHosp] = useState("");
  const [fReq, setFReq] = useState("");

  async function load() {
    setErr("");
    try {
      setCases(await apiFetch<CaseItem[]>("/api/cases"));
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

  async function search() {
    setResults(null);
    setSearched(true);
    if (!q.trim()) return;
    try {
      setResults(await apiFetch<SearchResult[]>(`/api/cases/search?q=${encodeURIComponent(q)}`));
    } catch (e) {
      setErr(e instanceof Error ? e.message : "Search failed");
    }
  }

  async function create() {
    try {
      const out = await apiFetch<{ message: string }>("/api/cases", {
        method: "POST",
        body: JSON.stringify({
          title: fTitle,
          narrative: fNarr,
          caseType: fType,
          severity: fSev,
          priorityLabel: fPrio,
          bloodGroup: fBlood,
          resourceType: fRes,
          patientAgeGroup: fAge,
          tags: fTags,
          hospitalIds: fHosp,
          linkedRequestIds: fReq,
        }),
      });
      flash(out.message);
      setShowNew(false);
      setFTitle("");
      setFNarr("");
      setFTags("");
      setFHosp("");
      setFReq("");
      load();
    } catch (e) {
      flash(e instanceof Error ? e.message : "Failed");
    }
  }

  return (
    <Shell>
      <div className="mb-4 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-800">Emergency Cases</h1>
          <p className="text-xs text-gray-400">
            Stored as documents in LanceDB (vector database) with semantic similarity search.
          </p>
        </div>
        <Button onClick={() => setShowNew(true)}>+ New Case</Button>
      </div>
      {err && <div className="mb-3 rounded-lg bg-red-50 px-3 py-2 text-sm text-red-700">{err}</div>}
      {msg && <div className="mb-3 rounded-lg bg-green-50 px-3 py-2 text-sm text-green-700">{msg}</div>}

      <Card title="Semantic search (vector similarity)">
        <div className="flex gap-2">
          <Input
            className="grow"
            value={q}
            onChange={(e) => setQ(e.target.value)}
            placeholder="e.g. multi-victim road accident needing O- and ICU beds"
            onKeyDown={(e) => {
              if (e.key === "Enter") search();
            }}
          />
          <Button onClick={search}>Search</Button>
          {searched && (
            <Button variant="ghost" onClick={() => { setResults(null); setSearched(false); setQ(""); }}>
              Clear
            </Button>
          )}
        </div>
        {results && (
          <div className="mt-4 space-y-3">
            {results.length === 0 ? (
              <EmptyState message="No similar cases found" />
            ) : (
              results.map((r, i) => (
                <Link
                  key={i}
                  href={`/cases/${r.case.caseId}`}
                  className="block rounded-lg border border-gray-200 p-3 hover:bg-gray-50"
                >
                  <div className="flex items-center justify-between">
                    <div className="font-medium text-gray-800">{r.case.title}</div>
                    <Badge className="border-purple-200 bg-purple-100 text-purple-700">
                      {similarityPct(r.score)} match
                    </Badge>
                  </div>
                  <div className="mt-1 line-clamp-2 text-sm text-gray-500">{r.case.narrative}</div>
                  <div className="mt-2 flex flex-wrap gap-1.5 text-xs">
                    <Badge className={statusColor(r.case.status)}>{r.case.status}</Badge>
                    <Badge className={priorityColor(r.case.severity)}>{r.case.severity}</Badge>
                    <Badge className="bg-gray-100">{r.case.caseType}</Badge>
                  </div>
                </Link>
              ))
            )}
          </div>
        )}
      </Card>

      <Card title={`All cases (${cases.length})`} className="mt-6">
        {cases.length === 0 ? (
          <EmptyState message="No cases yet. Create one or run the vector seed (npm run seed:vectors)." />
        ) : (
          <div className="grid gap-3 md:grid-cols-2">
            {cases.map((c) => (
              <Link
                key={c.caseId}
                href={`/cases/${c.caseId}`}
                className="block rounded-lg border border-gray-200 p-4 hover:border-brand-200 hover:bg-red-50/30"
              >
                <div className="flex items-center justify-between">
                  <div className="font-medium text-gray-800">{c.title}</div>
                  <Badge className={statusColor(c.status)}>{c.status}</Badge>
                </div>
                <div className="mt-1 line-clamp-2 text-sm text-gray-500">{c.narrative}</div>
                <div className="mt-2 flex flex-wrap gap-1.5 text-xs">
                  <Badge className={priorityColor(c.severity)}>{c.severity}</Badge>
                  <Badge className="bg-gray-100">{c.caseType}</Badge>
                  {c.bloodGroup && <Badge className="bg-gray-100">{c.bloodGroup}</Badge>}
                  {c.resourceType && <Badge className="bg-gray-100">{c.resourceType}</Badge>}
                </div>
                <div className="mt-2 text-xs text-gray-400">
                  {c.caseId} · {formatDate(c.createdAt)} · {c.createdByName}
                </div>
              </Link>
            ))}
          </div>
        )}
      </Card>

      <Modal open={showNew} onClose={() => setShowNew(false)} title="New emergency case">
        <div className="max-h-[70vh] space-y-3 overflow-y-auto">
          <Input label="Title" value={fTitle} onChange={(e) => setFTitle(e.target.value)} />
          <label className="block">
            <span className="mb-1 block text-sm font-medium text-gray-700">Narrative</span>
            <textarea
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-brand-500 focus:outline-none focus:ring-1 focus:ring-brand-500"
              rows={4}
              value={fNarr}
              onChange={(e) => setFNarr(e.target.value)}
              placeholder="Describe the emergency incident in detail..."
            />
          </label>
          <div className="grid grid-cols-2 gap-3">
            <Select label="Case type" value={fType} onChange={(e) => setFType(e.target.value)}>
              <option value="BLOOD">BLOOD</option>
              <option value="RESOURCE">RESOURCE</option>
              <option value="MULTI">MULTI</option>
            </Select>
            <Select label="Severity" value={fSev} onChange={(e) => setFSev(e.target.value)}>
              <option>CRITICAL</option><option>HIGH</option><option>MEDIUM</option><option>LOW</option>
            </Select>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <Input label="Blood group (optional)" value={fBlood} onChange={(e) => setFBlood(e.target.value)} placeholder="O-" />
            <Input label="Resource type (optional)" value={fRes} onChange={(e) => setFRes(e.target.value)} placeholder="ICU Bed" />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <Input label="Priority label (optional)" value={fPrio} onChange={(e) => setFPrio(e.target.value)} placeholder="e.g. TRAUMA" />
            <Select label="Patient age group" value={fAge} onChange={(e) => setFAge(e.target.value)}>
              <option value="adult">adult</option>
              <option value="pediatric">pediatric</option>
              <option value="neonatal">neonatal</option>
              <option value="geriatric">geriatric</option>
            </Select>
          </div>
          <Input label="Tags (comma separated)" value={fTags} onChange={(e) => setFTags(e.target.value)} placeholder="trauma, accident, pediatric" />
          <Input label="Hospital IDs (comma separated)" value={fHosp} onChange={(e) => setFHosp(e.target.value)} placeholder="1,3" />
          <Input label="Linked request IDs (comma separated)" value={fReq} onChange={(e) => setFReq(e.target.value)} placeholder="1,2" />
          <Button className="w-full" onClick={create}>Create case</Button>
        </div>
      </Modal>
    </Shell>
  );
}
