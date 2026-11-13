-- =============================================================
-- FILE   : 05_stored_procedure_and_function.sql
-- PURPOSE: Advanced database features
--
-- 1. Stored Procedure: find_available_resources
-- 2. Stored Function : calculate_emergency_priority
--
-- DATABASE: emergency_system
-- MYSQL   : 8.0.33
-- =============================================================

USE emergency_system;


-- =============================================================
-- STEP 1: Remove existing routines before recreating them
-- Safe to rerun; does not delete table data.
-- =============================================================

DROP PROCEDURE IF EXISTS find_available_resources;
DROP FUNCTION IF EXISTS calculate_emergency_priority;

DELIMITER //


-- =============================================================
-- STEP 2: STORED PROCEDURE
-- find_available_resources
--
-- Purpose:
-- Finds hospitals with available stock of a requested resource.
--
-- Example:
-- CALL find_available_resources('ICU Bed');
-- =============================================================

CREATE PROCEDURE find_available_resources(
    IN p_type VARCHAR(50)
)
BEGIN

    SELECT
        r.resource_id,
        h.hospital_id,
        h.hospital_name,
        h.city,
        r.resource_name,
        r.resource_type,
        r.total_quantity,
        r.available_quantity,
        r.status AS resource_status

    FROM resource r

    JOIN hospital h
        ON h.hospital_id = r.hospital_id

    WHERE r.resource_type = p_type
      AND r.available_quantity > 0
      AND r.status = 'AVAILABLE'
      AND h.status = 'ACTIVE'

    ORDER BY
        r.available_quantity DESC,
        h.hospital_name ASC;

END //


-- =============================================================
-- STEP 3: STORED FUNCTION
-- calculate_emergency_priority
--
-- Priority scores:
-- CRITICAL = 4
-- HIGH     = 3
-- MEDIUM   = 2
-- LOW      = 1
--
-- Additional rule:
-- Add 1 if the required_by deadline has passed.
--
-- Invalid or NULL priorities raise an error.
--
-- Example:
-- SELECT calculate_emergency_priority(
--     'CRITICAL', '2026-11-10 10:00:00'
-- );
-- =============================================================

CREATE FUNCTION calculate_emergency_priority(
    p_priority VARCHAR(10),
    p_required_by DATETIME
)
RETURNS INT
NOT DETERMINISTIC
NO SQL
BEGIN

    DECLARE v_score INT DEFAULT 0;

    -- Validate priority input
    IF p_priority IS NULL
       OR p_priority NOT IN ('CRITICAL', 'HIGH', 'MEDIUM', 'LOW') THEN

        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Invalid emergency priority';

    END IF;

    -- Assign base priority score
    SET v_score = CASE p_priority
        WHEN 'CRITICAL' THEN 4
        WHEN 'HIGH'     THEN 3
        WHEN 'MEDIUM'   THEN 2
        WHEN 'LOW'      THEN 1
    END;

    -- Add urgency bonus if deadline has passed
    IF p_required_by IS NOT NULL
       AND p_required_by < NOW() THEN

        SET v_score = v_score + 1;

    END IF;

    RETURN v_score;

END //

DELIMITER ;


-- =============================================================
-- END OF FILE
-- =============================================================
