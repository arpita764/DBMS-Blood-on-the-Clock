import "server-only";
import { getPool } from "./db";

// MySQL stored procedures use OUT parameters, which mysql2 cannot return
// directly. We run the CALL with @-prefixed session variables, then SELECT
// them back. Both statements must run on the SAME connection so the session
// variables persist.

async function callWithOutVars(
  callSql: string,
  params: unknown[],
  selectSql: string
): Promise<Record<string, unknown>> {
  const conn = await getPool().getConnection();
  try {
    await conn.query(callSql, params);
    const [rows] = await conn.query(selectSql);
    return (rows as Record<string, unknown>[])[0] ?? {};
  } finally {
    conn.release();
  }
}

export function reserveBlood(
  requestId: number,
  supplierHospitalId: number,
  units: number,
  reservedBy: number
) {
  return callWithOutVars(
    "CALL reserve_blood(?, ?, ?, ?, @p_reservation_id, @p_message)",
    [requestId, supplierHospitalId, units, reservedBy],
    "SELECT @p_reservation_id AS reservation_id, @p_message AS message"
  );
}

export function fulfillReservation(reservationId: number, fulfilledBy: number) {
  return callWithOutVars(
    "CALL fulfill_reservation(?, ?, @p_message)",
    [reservationId, fulfilledBy],
    "SELECT @p_message AS message"
  );
}

export function releaseReservation(reservationId: number, releasedBy: number) {
  return callWithOutVars(
    "CALL release_reservation(?, ?, @p_message)",
    [reservationId, releasedBy],
    "SELECT @p_message AS message"
  );
}

export function cancelRequest(requestId: number, cancelledBy: number) {
  return callWithOutVars(
    "CALL cancel_request(?, ?, @p_message)",
    [requestId, cancelledBy],
    "SELECT @p_message AS message"
  );
}

export function allocateResource(
  resourceRequestId: number,
  resourceId: number,
  units: number,
  allocatedBy: number
) {
  return callWithOutVars(
    "CALL allocate_resource_for_request(?, ?, ?, ?, @p_message)",
    [resourceRequestId, resourceId, units, allocatedBy],
    "SELECT @p_message AS message"
  );
}

export function cancelResourceRequest(
  resourceRequestId: number,
  cancelledBy: number
) {
  return callWithOutVars(
    "CALL cancel_resource_request(?, ?, @p_message)",
    [resourceRequestId, cancelledBy],
    "SELECT @p_message AS message"
  );
}
