import { NextRequest } from "next/server";
import { handleApi, json } from "@/lib/http";
import { requireUser } from "@/lib/auth";
import { query } from "@/lib/db";

export async function GET(req: NextRequest) {
  return handleApi(async () => {
    await requireUser();
    const { searchParams } = new URL(req.url);
    const q = searchParams.get("q")?.trim();
    const city = searchParams.get("city");

    // Full-text search (Unit 2): requires the FULLTEXT index from
    // 11_advanced_sql_coverage.sql to have been applied.
    if (q) {
      const rows = await query(
        `SELECT hospital_id, hospital_name, address, city, phone,
                hospital_type, status,
                MATCH(hospital_name, city, hospital_type)
                  AGAINST(? IN NATURAL LANGUAGE MODE) AS relevance
           FROM hospital
          WHERE MATCH(hospital_name, city, hospital_type)
                  AGAINST(? IN NATURAL LANGUAGE MODE)
          ORDER BY relevance DESC`,
        [q, q]
      );
      return json(rows);
    }

    let sql = `SELECT hospital_id, hospital_name, address, city, phone,
                      hospital_type, status
                 FROM hospital WHERE 1=1`;
    const params: unknown[] = [];
    if (city) {
      sql += " AND city = ?";
      params.push(city);
    }
    sql += " ORDER BY city, hospital_name";
    return json(await query(sql, params));
  });
}
