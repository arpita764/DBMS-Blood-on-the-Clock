import { NextRequest } from "next/server";
import { handleApi, json, HttpError } from "@/lib/http";
import { requireUser } from "@/lib/auth";
import { query } from "@/lib/db";
import { createCase, listCases } from "@/lib/vector";
import type { EmergencyCase } from "@/lib/types";

interface CaseCreateBody {
  title?: string;
  narrative?: string;
  caseType?: string;
  severity?: string;
  priorityLabel?: string;
  bloodGroup?: string;
  resourceType?: string;
  patientAgeGroup?: string;
  hospitalIds?: number[] | string;
  tags?: string[] | string;
  linkedRequestIds?: number[] | string;
}

export async function GET() {
  return handleApi(async () => {
    await requireUser();
    return json(await listCases());
  });
}

export async function POST(req: NextRequest) {
  return handleApi(async () => {
    const user = await requireUser();
    const b = (await req.json()) as CaseCreateBody;

    const title = String(b.title || "").trim();
    const narrative = String(b.narrative || "").trim();
    const caseType = String(b.caseType || "").trim();
    const severity = String(b.severity || "").trim();
    if (!title || !narrative || !caseType || !severity) {
      throw new HttpError(400, "Title, narrative, caseType and severity are required");
    }
    if (!["BLOOD", "RESOURCE", "MULTI"].includes(caseType)) {
      throw new HttpError(400, "caseType must be BLOOD, RESOURCE or MULTI");
    }
    if (!["CRITICAL", "HIGH", "MEDIUM", "LOW"].includes(severity)) {
      throw new HttpError(400, "Invalid severity");
    }

    const toNumberList = (v: number[] | string | undefined): number[] => {
      if (Array.isArray(v)) return v.map(Number).filter((n: number) => n > 0);
      return String(v || "")
        .split(",")
        .map((s) => Number(s.trim()))
        .filter((n) => Number.isFinite(n) && n > 0);
    };

    const hospitalIds = toNumberList(b.hospitalIds);

    let hospitalNames: string[] = [];
    if (hospitalIds.length) {
      const ph = hospitalIds.map(() => "?").join(",");
      const rows = await query<{ hospital_name: string }>(
        `SELECT hospital_name FROM hospital WHERE hospital_id IN (${ph})`,
        hospitalIds
      );
      hospitalNames = rows.map((r) => r.hospital_name);
    }

    const tags: string[] = Array.isArray(b.tags)
      ? b.tags.map(String)
      : String(b.tags || "")
          .split(",")
          .map((s) => s.trim())
          .filter(Boolean);

    const linkedRequestIds = toNumberList(b.linkedRequestIds);

    const now = new Date().toISOString();
    const c: EmergencyCase = {
      caseId: "EMG-" + Date.now().toString(36).toUpperCase(),
      title,
      narrative,
      caseType: caseType as EmergencyCase["caseType"],
      severity: severity as EmergencyCase["severity"],
      priorityLabel: String(b.priorityLabel || severity),
      bloodGroup: b.bloodGroup ? String(b.bloodGroup) : null,
      resourceType: b.resourceType ? String(b.resourceType) : null,
      patientAgeGroup: String(b.patientAgeGroup || "adult"),
      status: "OPEN",
      createdBy: user.userId,
      createdByName: user.name,
      createdAt: now,
      updatedAt: now,
      hospitalIds,
      hospitalNames,
      tags,
      linkedRequestIds,
      timeline: [{ at: now, actor: user.name, event: "CREATED", note: "Case opened" }],
    };

    await createCase(c);
    return json({ caseId: c.caseId, message: "Emergency case created and embedded" });
  });
}
