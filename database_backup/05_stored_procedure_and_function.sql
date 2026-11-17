-- =============================================================
-- MEMBER 2 – Advanced DB Features:
--   1. Stored Procedure : find_available_resources(type)
--   2. Stored Function  : calculate_emergency_priority(priority, deadline)
-- =============================================================
USE emergency_system;

DELIMITER //

-- -----------------------------------------------------------
-- Procedure: find_available_resources
-- Returns hospitals that have available stock of a given
-- resource type (e.g. 'ICU Bed', 'Ventilator', 'Ambulance')
-- Call: CALL find_available_resources('ICU Bed');
-- -----------------------------------------------------------
CREATE PROCEDURE find_available_resources(IN p_type VARCHAR(50))
BEGIN
  SELECT
    h.hospital_name,
    h.city,
    r.resource_name,
    r.resource_type,
    r.available_quantity
  FROM resource r
  JOIN hospital h ON h.hospital_id = r.hospital_id
  WHERE r.resource_type     = p_type
    AND r.available_quantity > 0
    AND r.status             = 'AVAILABLE'
    AND h.status             = 'ACTIVE'
  ORDER BY r.available_quantity DESC;
END //

-- -----------------------------------------------------------
-- Function: calculate_emergency_priority
-- Returns a numeric urgency score for sorting requests:
--   CRITICAL = 4, HIGH = 3, MEDIUM = 2, LOW = 1
--   +1 bonus if required_by deadline has already passed
-- Usage: SELECT calculate_emergency_priority('CRITICAL', required_by)
-- -----------------------------------------------------------
CREATE FUNCTION calculate_emergency_priority(
  p_priority    VARCHAR(10),
  p_required_by DATETIME
) RETURNS INT DETERMINISTIC
BEGIN
  DECLARE v_score INT DEFAULT 0;

  SET v_score = CASE p_priority
    WHEN 'CRITICAL' THEN 4
    WHEN 'HIGH'     THEN 3
    WHEN 'MEDIUM'   THEN 2
    ELSE 1
  END;

  -- Boost if deadline is already overdue
  IF p_required_by IS NOT NULL AND p_required_by < NOW() THEN
    SET v_score = v_score + 1;
  END IF;

  RETURN v_score;
END //

DELIMITER ;
