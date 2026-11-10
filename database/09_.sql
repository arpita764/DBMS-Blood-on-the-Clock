USE emergency_system;

-- 1. Pending emergencies in priority order (uses Member 2's function)
SELECT request_id, hospital_id, quantity_required, priority, required_by,
       calculate_emergency_priority(priority, required_by) AS score
FROM emergency_request
WHERE status = 'PENDING'
ORDER BY score DESC, required_by ASC;

-- 2. Requests per blood group (GROUP BY + COUNT)
SELECT bg.group_name, COUNT(*) AS total_requests
FROM emergency_request er
JOIN blood_group bg ON bg.blood_group_id = er.blood_group_id
GROUP BY bg.group_name
ORDER BY total_requests DESC;

-- 3. Available units per hospital (SUM + HAVING)
SELECT h.hospital_name, SUM(bi.available_units) AS total_available
FROM blood_inventory bi
JOIN hospital h ON h.hospital_id = bi.hospital_id
GROUP BY h.hospital_name
HAVING SUM(bi.available_units) > 5;

-- 4. Hospitals with enough stock for request 1 (exact group only)
SELECT h.hospital_name, bi.available_units
FROM blood_inventory bi
JOIN hospital h ON h.hospital_id = bi.hospital_id
WHERE h.status = 'ACTIVE'
  AND bi.blood_group_id = (SELECT blood_group_id FROM emergency_request WHERE request_id = 1)
  AND bi.available_units >= (SELECT quantity_required FROM emergency_request WHERE request_id = 1);

-- 5. Requests that cannot be fulfilled now (subquery)
SELECT er.request_id, er.quantity_required
FROM emergency_request er
WHERE er.status = 'PENDING'
  AND er.quantity_required > (
    SELECT COALESCE(MAX(bi.available_units), 0)
    FROM blood_inventory bi
    JOIN blood_compatibility bc ON bc.donor_group_id = bi.blood_group_id
    JOIN hospital h ON h.hospital_id = bi.hospital_id AND h.status = 'ACTIVE'
    WHERE bc.recipient_group_id = er.blood_group_id);

-- 6. DELETE example (cancelled requests with no reservation)
DELETE FROM emergency_request
WHERE status = 'CANCELLED'
  AND request_id NOT IN (SELECT request_id FROM blood_reservation);