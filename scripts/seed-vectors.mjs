// =====================================================================
// seed-vectors.mjs
// One-time seed for the vector database (LanceDB). Creates the
// emergency_cases table and inserts sample case documents, each with a
// 384-dim embedding produced by Xenova/all-MiniLM-L6-v2.
//
// Run:  npm run seed:vectors   (uses --env-file=.env.local in package.json)
//
// On the first run the embedding model (~25MB) is downloaded from the
// Hugging Face Hub into ./data/.models and then cached for offline use.
// =====================================================================

import * as lancedb from "@lancedb/lancedb";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "..");

const DB_PATH = process.env.VECTORDV_PATH || "./data/vectordb";
const CASES_TABLE = "emergency_cases";

let extractorPromise = null;
async function getExtractor() {
  if (!extractorPromise) {
    const { pipeline, env } = await import("@huggingface/transformers");
    env.cacheDir = path.resolve(ROOT, "./data/.models");
    env.allowLocalModels = false;
    console.log("Loading embedding model Xenova/all-MiniLM-L6-v2 (first run downloads ~25MB)...");
    extractorPromise = await pipeline("feature-extraction", "Xenova/all-MiniLM-L6-v2");
  }
  return extractorPromise;
}

async function embed(text) {
  const ex = await getExtractor();
  const out = await ex(text, { pooling: "mean", normalize: true });
  return Array.from(out.data);
}

function embeddingText(c) {
  return [c.title, c.narrative, c.caseType, c.severity, (c.tags || []).join(" "), c.bloodGroup || "", c.resourceType || ""]
    .filter(Boolean)
    .join(" ");
}

function toRow(c, vector) {
  return {
    caseId: c.caseId,
    title: c.title,
    narrative: c.narrative,
    caseType: c.caseType,
    severity: c.severity,
    priorityLabel: c.priorityLabel,
    bloodGroup: c.bloodGroup || "",
    resourceType: c.resourceType || "",
    patientAgeGroup: c.patientAgeGroup || "adult",
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

const SEED_CASES = [
  {
    caseId: "EMG-SEED-01",
    title: "Multi-victim highway collision, mass trauma",
    narrative:
      "A multi-vehicle collision on the highway brought several critically injured patients needing emergency surgery. O- blood is urgently required for transfusions and multiple ICU beds and ventilators are needed for post-operative care. Several victims are in haemorrhagic shock.",
    caseType: "MULTI",
    severity: "CRITICAL",
    priorityLabel: "MASS-CASUALTY",
    bloodGroup: "O-",
    resourceType: "ICU Bed",
    patientAgeGroup: "adult",
    status: "RESOLVED",
    tags: ["trauma", "accident", "mass-casualty", "haemorrhage", "highway"],
    hospitalIds: [3],
    hospitalNames: ["Metro Trauma Centre"],
    linkedRequestIds: [1],
    createdBy: 4,
    createdByName: "Anjali Mehta",
    createdAt: "2026-10-28T09:30:00.000Z",
    updatedAt: "2026-10-29T18:00:00.000Z",
    timeline: [
      { at: "2026-10-28T09:30:00.000Z", actor: "Anjali Mehta", event: "CREATED", note: "Case opened" },
      { at: "2026-10-28T10:15:00.000Z", actor: "Anjali Mehta", event: "BLOOD_RESERVED", note: "5 units O- reserved from Apollo Blood Bank" },
      { at: "2026-10-28T11:00:00.000Z", actor: "Anjali Mehta", event: "RESOURCE_ALLOCATED", note: "3 ICU beds allocated" },
      { at: "2026-10-29T18:00:00.000Z", actor: "Anjali Mehta", event: "STATUS_CHANGED", note: "Status set to RESOLVED" },
    ],
  },
  {
    caseId: "EMG-SEED-02",
    title: "Dengue outbreak, platelet demand spike",
    narrative:
      "A seasonal dengue fever outbreak has caused a sharp rise in thrombocytopenia cases. Multiple hospitals need B+ and AB+ blood for platelet concentrate transfusions. Demand for ICU observation beds is also rising for severe patients.",
    caseType: "BLOOD",
    severity: "HIGH",
    priorityLabel: "OUTBREAK",
    bloodGroup: "B+",
    resourceType: null,
    patientAgeGroup: "adult",
    status: "OPEN",
    tags: ["dengue", "outbreak", "platelets", "seasonal"],
    hospitalIds: [2, 4],
    hospitalNames: ["Apollo Blood Bank", "Sunrise Medical Centre"],
    linkedRequestIds: [],
    createdBy: 3,
    createdByName: "Rajan Nair",
    createdAt: "2026-11-05T08:00:00.000Z",
    updatedAt: "2026-11-06T12:00:00.000Z",
    timeline: [
      { at: "2026-11-05T08:00:00.000Z", actor: "Rajan Nair", event: "CREATED", note: "Case opened" },
      { at: "2026-11-06T12:00:00.000Z", actor: "Rajan Nair", event: "ESCALATION", note: "Platelet demand doubled overnight" },
    ],
  },
  {
    caseId: "EMG-SEED-03",
    title: "Building collapse, crushed patients",
    narrative:
      "A partial building collapse trapped several construction workers. Victims present with crush injuries requiring ventilator support and emergency surgery. High-flow ventilators and trauma ICU beds are the critical resource gap. Blood demand is moderate.",
    caseType: "RESOURCE",
    severity: "HIGH",
    priorityLabel: "DISASTER",
    bloodGroup: null,
    resourceType: "Ventilator",
    patientAgeGroup: "adult",
    status: "RESOLVED",
    tags: ["disaster", "collapse", "crush-injury", "ventilator"],
    hospitalIds: [1, 3],
    hospitalNames: ["City General Hospital", "Metro Trauma Centre"],
    linkedRequestIds: [],
    createdBy: 2,
    createdByName: "Priya Sharma",
    createdAt: "2026-09-18T14:00:00.000Z",
    updatedAt: "2026-09-20T10:00:00.000Z",
    timeline: [
      { at: "2026-09-18T14:00:00.000Z", actor: "Priya Sharma", event: "CREATED", note: "Case opened" },
      { at: "2026-09-18T15:30:00.000Z", actor: "Priya Sharma", event: "RESOURCE_ALLOCATED", note: "2 ventilators allocated" },
      { at: "2026-09-20T10:00:00.000Z", actor: "Priya Sharma", event: "STATUS_CHANGED", note: "Status set to RESOLVED" },
    ],
  },
  {
    caseId: "EMG-SEED-04",
    title: "Postpartum haemorrhage, emergency delivery",
    narrative:
      "A postpartum haemorrhage following an emergency caesarean section requires urgent O+ blood transfusion. The patient is haemodynamically unstable and being managed in the labour ward ICU. Rapid blood availability is critical.",
    caseType: "BLOOD",
    severity: "CRITICAL",
    priorityLabel: "OBSTETRIC",
    bloodGroup: "O+",
    resourceType: null,
    patientAgeGroup: "adult",
    status: "OPEN",
    tags: ["obstetric", "haemorrhage", "postpartum", "maternal"],
    hospitalIds: [1],
    hospitalNames: ["City General Hospital"],
    linkedRequestIds: [],
    createdBy: 2,
    createdByName: "Priya Sharma",
    createdAt: "2026-11-10T03:20:00.000Z",
    updatedAt: "2026-11-10T04:00:00.000Z",
    timeline: [
      { at: "2026-11-10T03:20:00.000Z", actor: "Priya Sharma", event: "CREATED", note: "Case opened" },
      { at: "2026-11-10T03:45:00.000Z", actor: "Priya Sharma", event: "BLOOD_RESERVED", note: "3 units O+ reserved" },
    ],
  },
  {
    caseId: "EMG-SEED-05",
    title: "Paediatric leukaemia chemotherapy support",
    narrative:
      "A paediatric leukaemia patient undergoing induction chemotherapy needs scheduled AB+ blood and platelet transfusions to manage chemotherapy-induced thrombocytopenia. This is a recurring, planned requirement rather than a one-off trauma.",
    caseType: "BLOOD",
    severity: "MEDIUM",
    priorityLabel: "ONCOLOGY",
    bloodGroup: "AB+",
    resourceType: null,
    patientAgeGroup: "pediatric",
    status: "OPEN",
    tags: ["paediatric", "oncology", "leukaemia", "chemotherapy", "planned"],
    hospitalIds: [4],
    hospitalNames: ["Sunrise Medical Centre"],
    linkedRequestIds: [],
    createdBy: 5,
    createdByName: "Suresh Pillai",
    createdAt: "2026-11-01T07:00:00.000Z",
    updatedAt: "2026-11-02T09:00:00.000Z",
    timeline: [
      { at: "2026-11-01T07:00:00.000Z", actor: "Suresh Pillai", event: "CREATED", note: "Case opened" },
      { at: "2026-11-02T09:00:00.000Z", actor: "Suresh Pillai", event: "PATIENT_UPDATE", note: "Cycle 2 transfusion scheduled" },
    ],
  },
  {
    caseId: "EMG-SEED-06",
    title: "Industrial fire, severe burns",
    narrative:
      "An industrial fire caused severe burns to multiple workers. Patients need ICU beds, ventilators for inhalation injury, and O- and O+ blood for surgical debridement and grafting. This is a multi-casualty incident with high resource and blood demand.",
    caseType: "MULTI",
    severity: "HIGH",
    priorityLabel: "BURNS",
    bloodGroup: "O-",
    resourceType: "Ventilator",
    patientAgeGroup: "adult",
    status: "OPEN",
    tags: ["burns", "fire", "industrial", "multi-casualty", "inhalation-injury"],
    hospitalIds: [3, 1],
    hospitalNames: ["Metro Trauma Centre", "City General Hospital"],
    linkedRequestIds: [],
    createdBy: 4,
    createdByName: "Anjali Mehta",
    createdAt: "2026-11-08T20:00:00.000Z",
    updatedAt: "2026-11-09T06:00:00.000Z",
    timeline: [
      { at: "2026-11-08T20:00:00.000Z", actor: "Anjali Mehta", event: "CREATED", note: "Case opened" },
      { at: "2026-11-09T06:00:00.000Z", actor: "Anjali Mehta", event: "ESCALATION", note: "Inhalation injuries require additional ventilators" },
    ],
  },
  {
    caseId: "EMG-SEED-07",
    title: "Respiratory surge, seasonal flu complications",
    narrative:
      "A seasonal influenza surge has led to respiratory failure in elderly patients needing ventilator and ICU support. Blood demand is low but critical care capacity is strained. Most patients are geriatric with comorbidities.",
    caseType: "RESOURCE",
    severity: "MEDIUM",
    priorityLabel: "RESPIRATORY",
    bloodGroup: null,
    resourceType: "Ventilator",
    patientAgeGroup: "geriatric",
    status: "RESOLVED",
    tags: ["respiratory", "seasonal", "geriatric", "ventilator"],
    hospitalIds: [1, 2],
    hospitalNames: ["City General Hospital", "Apollo Blood Bank"],
    linkedRequestIds: [],
    createdBy: 2,
    createdByName: "Priya Sharma",
    createdAt: "2026-08-12T11:00:00.000Z",
    updatedAt: "2026-08-18T16:00:00.000Z",
    timeline: [
      { at: "2026-08-12T11:00:00.000Z", actor: "Priya Sharma", event: "CREATED", note: "Case opened" },
      { at: "2026-08-18T16:00:00.000Z", actor: "Priya Sharma", event: "STATUS_CHANGED", note: "Status set to RESOLVED" },
    ],
  },
];

async function main() {
  console.log(`Connecting to LanceDB at ${path.resolve(ROOT, DB_PATH)} ...`);
  const db = await lancedb.connect(path.resolve(ROOT, DB_PATH));
  const names = await db.tableNames();
  if (Array.from(names).includes(CASES_TABLE)) {
    console.log(`Dropping existing '${CASES_TABLE}' table for a clean seed...`);
    await db.dropTable(CASES_TABLE);
  }

  const rows = [];
  for (const c of SEED_CASES) {
    const vec = await embed(embeddingText(c));
    rows.push(toRow(c, vec));
    console.log(`  embedded ${c.caseId} (${c.title})`);
  }

  await db.createTable(CASES_TABLE, rows);
  console.log(`\nSeeded ${rows.length} emergency cases into LanceDB.`);
  console.log("Vector dimension: 384  |  model: Xenova/all-MiniLM-L6-v2");
}

main().catch((e) => {
  console.error("Seed failed:", e);
  process.exit(1);
});
