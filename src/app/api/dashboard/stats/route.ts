import { handleApi, json } from "@/lib/http";
import { requireUser } from "@/lib/auth";
import { query, getOne } from "@/lib/db";
import { caseStats } from "@/lib/vector";

export async function GET() {
  return handleApi(async () => {
    await requireUser();

    const [hospitalsActive, bloodRequestsOpen, resourceRequestsOpen, totalUnits, cases] =
      await Promise.all([
        getOne<{ c: number }>("SELECT COUNT(*) AS c FROM hospital WHERE status='ACTIVE'"),
        getOne<{ c: number }>(
          "SELECT COUNT(*) AS c FROM emergency_request WHERE status IN ('PENDING','RESERVED')"
        ),
        getOne<{ c: number }>(
          "SELECT COUNT(*) AS c FROM resource_request WHERE status IN ('PENDING','PARTIALLY_FULFILLED')"
        ),
        getOne<{ c: number }>(
          "SELECT COALESCE(SUM(available_units),0) AS c FROM blood_inventory"
        ),
        caseStats().catch(() => ({
          total: 0,
          byStatus: {} as Record<string, number>,
          bySeverity: {} as Record<string, number>,
          byType: {} as Record<string, number>,
        })),
      ]);

    const lowStock = await query(
      `SELECT h.hospital_name, h.city, bg.group_name, bi.available_units, bi.reserved_units
         FROM blood_inventory bi
         JOIN hospital h ON h.hospital_id = bi.hospital_id
         JOIN blood_group bg ON bg.blood_group_id = bi.blood_group_id
        WHERE bi.available_units < 5
        ORDER BY bi.available_units ASC`
    );

    const pendingByPriority = await query<{ priority: string; count: number }>(
      `SELECT priority, COUNT(*) AS count
         FROM emergency_request
        WHERE status IN ('PENDING','RESERVED')
        GROUP BY priority`
    );

    return json({
      hospitalsActive: hospitalsActive?.c ?? 0,
      bloodRequestsOpen: bloodRequestsOpen?.c ?? 0,
      resourceRequestsOpen: resourceRequestsOpen?.c ?? 0,
      totalAvailableUnits: totalUnits?.c ?? 0,
      casesOpen: cases.byStatus.OPEN ?? 0,
      casesTotal: cases.total,
      lowStock,
      pendingByPriority,
    });
  });
}
