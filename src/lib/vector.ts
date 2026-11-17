import "server-only";
import path from "node:path";
import type { CaseTimelineEvent, EmergencyCase } from "./types";

// =====================================================================
// Vector database layer.
//
// Paradigm: SQL stores the structured operational state (hospitals,
// inventory, requests, allocations). LanceDB stores the unstructured,
// text-heavy emergency case files and powers semantic similarity search
// ("find similar past emergencies"), which relational SQL cannot do well.
//
// Embeddings: text is converted to 384-dim vectors by the sentence
// embedding model `Xenova/all-MiniLM-L6-v2` (Transformers.js, ONNX runtime,
// runs locally in-process; no API key). Vectors are L2-normalised so the
// similarity metric is cosine similarity (dot product of normalised vectors).
// =====================================================================

const DB_PATH = process.env.VECTORDV_PATH || "./data/vectordb";
const CASES_TABLE = "emergency_cases";

let dbPromise: Promise<unknown> | null = null;
let extractorPromise: Promise<unknown> | null = null;

async function getDb(): Promise<any> {
  if (!dbPromise) {
    dbPromise = (async () => {
      const lancedb = (await import("@lancedb/lancedb")) as any;
      return await lancedb.connect(path.resolve(process.cwd(), DB_PATH));
    })();
  }
  return dbPromise;
}

async function getExtractor(): Promise<any> {
  if (!extractorPromise) {
    extractorPromise = (async () => {
      const { pipeline, env } = (await import(
        "@huggingface/transformers"
      )) as any;
      env.cacheDir = path.resolve(process.cwd(), "./data/.models");
      env.allowLocalModels = false;
      return await pipeline("feature-extraction", "Xenova/all-MiniLM-L6-v2");
    })();
  }
  return extractorPromise;
}

/** Convert text into a 384-dim L2-normalised embedding vector. */
export async function embed(text: string): Promise<number[]> {
  const extractor = await getExtractor();
  const output = await extractor(text, { pooling: "mean", normalize: true });
  return Array.from(output.data as Float32Array);
}

function embeddingText(c: EmergencyCase): string {
  return [
    c.title,
    c.narrative,
    c.caseType,
    c.severity,
    (c.tags || []).join(" "),
    c.bloodGroup || "",
    c.resourceType || "",
  ]
    .filter(Boolean)
    .join(" ");
}

function toRow(c: EmergencyCase, vector: number[]): Record<string, unknown> {
  return {
    caseId: c.caseId,
    title: c.title,
    narrative: c.narrative,
    caseType: c.caseType,
    severity: c.severity,
    priorityLabel: c.priorityLabel,
    bloodGroup: c.bloodGroup || "",
    resourceType: c.resourceType || "",
    patientAgeGroup: c.patientAgeGroup || "",
    status: c.status,
    createdBy: c.createdBy,
    createdByName: c.createdByName,
    createdAt: c.createdAt,
    updatedAt: c.updatedAt,
    hospitalIdsJson: JSON.stringify(c.hospitalIds || []),
    hospitalNamesJson: JSON.stringify(c.hospitalNames || []),
    tagsJson: JSON.stringify(c.tags || []),
    linkedRequestIdsJson: JSON.stringify(c.linkedRequestIds || []),
    timelineJson: JSON.stringify(c.timeline || []),
    vector,
  };
}

function fromRow(r: any): EmergencyCase {
  const parse = (s: string | undefined): unknown[] => {
    try {
      const v = JSON.parse(s || "[]");
      return Array.isArray(v) ? v : [];
    } catch {
      return [];
    }
  };
  return {
    caseId: String(r.caseId),
    title: String(r.title),
    narrative: String(r.narrative),
    caseType: r.caseType as EmergencyCase["caseType"],
    severity: r.severity as EmergencyCase["severity"],
    priorityLabel: String(r.priorityLabel ?? ""),
    bloodGroup: r.bloodGroup ? String(r.bloodGroup) : null,
    resourceType: r.resourceType ? String(r.resourceType) : null,
    patientAgeGroup: String(r.patientAgeGroup ?? ""),
    status: r.status as EmergencyCase["status"],
    createdBy: Number(r.createdBy),
    createdByName: String(r.createdByName ?? ""),
    createdAt: String(r.createdAt),
    updatedAt: String(r.updatedAt),
    hospitalIds: parse(r.hospitalIdsJson) as number[],
    hospitalNames: parse(r.hospitalNamesJson) as string[],
    tags: parse(r.tagsJson) as string[],
    linkedRequestIds: parse(r.linkedRequestIdsJson) as number[],
    timeline: parse(r.timelineJson) as CaseTimelineEvent[],
  };
}

/** Collect rows from a LanceDB query/vector-search builder. */
async function collect(builder: any): Promise<any[]> {
  if (typeof builder.toArray === "function") {
    return await builder.toArray();
  }
  const out: any[] = [];
  for await (const batch of builder) {
    if (Array.isArray(batch)) out.push(...batch);
    else out.push(batch);
  }
  return out;
}

async function tableExists(name: string): Promise<boolean> {
  const db = await getDb();
  const names: string[] = Array.from(await db.tableNames());
  return names.includes(name);
}

function validCaseId(id: string): boolean {
  return /^[A-Z0-9-]+$/.test(id);
}

/** Insert a case (auto-creates the table on first insert). */
export async function createCase(c: EmergencyCase): Promise<void> {
  const db = await getDb();
  const vec = await embed(embeddingText(c));
  const row = toRow(c, vec);
  if (await tableExists(CASES_TABLE)) {
    const table = await db.openTable(CASES_TABLE);
    await table.add([row]);
  } else {
    await db.createTable(CASES_TABLE, [row]);
  }
}

/** List all cases, newest first. */
export async function listCases(limit = 500): Promise<EmergencyCase[]> {
  const db = await getDb();
  if (!(await tableExists(CASES_TABLE))) return [];
  const table = await db.openTable(CASES_TABLE);
  const rows = await collect(table.query().limit(limit));
  return rows
    .map(fromRow)
    .sort((a, b) => b.createdAt.localeCompare(a.createdAt));
}

async function getRawRow(caseId: string): Promise<any | null> {
  if (!validCaseId(caseId)) return null;
  const db = await getDb();
  if (!(await tableExists(CASES_TABLE))) return null;
  const table = await db.openTable(CASES_TABLE);
  const rows = await collect(table.query().where(`caseId = '${caseId}'`).limit(1));
  return rows[0] ?? null;
}

export async function getCase(caseId: string): Promise<EmergencyCase | null> {
  const raw = await getRawRow(caseId);
  return raw ? fromRow(raw) : null;
}

/**
 * Semantic search: embed the query and find the nearest case vectors.
 * Returns cases ranked by cosine similarity (1.0 = identical meaning).
 */
export async function searchCases(
  query: string,
  limit = 5
): Promise<{ case: EmergencyCase; score: number }[]> {
  const db = await getDb();
  if (!(await tableExists(CASES_TABLE))) return [];
  const table = await db.openTable(CASES_TABLE);
  const qvec = await embed(query);
  const rows = await collect(table.vectorSearch(qvec).limit(limit));
  return rows
    .map((r) => {
      const v: number[] = Array.from(r.vector as any);
      let dot = 0;
      for (let i = 0; i < qvec.length; i++) dot += qvec[i] * (v[i] || 0);
      return { case: fromRow(r), score: dot };
    })
    .sort((a, b) => b.score - a.score);
}

/** Replace a case's row in place (used to mutate timeline / status). */
async function replaceRow(
  caseId: string,
  mutator: (raw: any) => any
): Promise<EmergencyCase | null> {
  const db = await getDb();
  if (!(await tableExists(CASES_TABLE))) return null;
  const raw = await getRawRow(caseId);
  if (!raw) return null;
  const updated = mutator(raw);
  const table = await db.openTable(CASES_TABLE);
  await table.delete(`caseId = '${caseId}'`);
  await table.add([updated]);
  return fromRow(updated);
}

export async function addTimelineEvent(
  caseId: string,
  event: CaseTimelineEvent
): Promise<EmergencyCase | null> {
  return replaceRow(caseId, (raw) => {
    let timeline: CaseTimelineEvent[] = [];
    try {
      const v = JSON.parse(raw.timelineJson ?? "[]");
      if (Array.isArray(v)) timeline = v;
    } catch {
      /* ignore */
    }
    timeline.push(event);
    return {
      ...raw,
      timelineJson: JSON.stringify(timeline),
      updatedAt: event.at,
    };
  });
}

export async function updateCaseStatus(
  caseId: string,
  status: EmergencyCase["status"],
  actor: string
): Promise<EmergencyCase | null> {
  const now = new Date().toISOString();
  return replaceRow(caseId, (raw) => {
    let timeline: CaseTimelineEvent[] = [];
    try {
      const v = JSON.parse(raw.timelineJson ?? "[]");
      if (Array.isArray(v)) timeline = v;
    } catch {
      /* ignore */
    }
    timeline.push({
      at: now,
      actor,
      event: "STATUS_CHANGED",
      note: `Status set to ${status}`,
    });
    return {
      ...raw,
      status,
      timelineJson: JSON.stringify(timeline),
      updatedAt: now,
    };
  });
}

/** Aggregate counts for the case dashboard tile (NoSQL-style aggregation). */
export async function caseStats(): Promise<{
  total: number;
  byStatus: Record<string, number>;
  bySeverity: Record<string, number>;
  byType: Record<string, number>;
}> {
  const all = await listCases(1000);
  const byStatus: Record<string, number> = {};
  const bySeverity: Record<string, number> = {};
  const byType: Record<string, number> = {};
  for (const c of all) {
    byStatus[c.status] = (byStatus[c.status] || 0) + 1;
    bySeverity[c.severity] = (bySeverity[c.severity] || 0) + 1;
    byType[c.caseType] = (byType[c.caseType] || 0) + 1;
  }
  return { total: all.length, byStatus, bySeverity, byType };
}
