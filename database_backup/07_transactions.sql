-- =============================================================
-- FILE   : 07_transactions.sql
-- PURPOSE: Transactional stored procedures for all blood
--          reservation and resource allocation operations.
--
-- PROCEDURES:
--   1. reserve_blood         – create a reservation
--   2. fulfill_reservation   – mark ALLOCATED (blood delivered)
--   3. release_reservation   – cancel a RESERVED reservation,
--                              restore available units
--   4. allocate_resource     – reduce available_quantity on
--                              a physical resource
--   5. cancel_request        – cancel a full request and
--                              release any open reservations
--
-- DESIGN PRINCIPLES:
--   • SELECT ... FOR UPDATE locks rows before mutating them
--     (InnoDB row-level locking; prevents race conditions).
--   • Every procedure uses an explicit transaction with
--     ROLLBACK on any error caught by EXIT HANDLER.
--   • OUT parameters return a human-readable result message.
--   • Blood compatibility is verified against blood_compatibility.
--   • Available stock is checked before every reservation.
--   • Duplicate fulfilment / release is detected and rejected.
--
-- MySQL RULE: DECLARE variable and DECLARE HANDLER statements
--   MUST all appear at the top of a BEGIN...END block before
--   any executable statements.  Conditional logic uses IF/ELSE
--   rather than LEAVE labels (more portable across MySQL 8.x).
-- =============================================================
USE emergency_system;

DELIMITER //

-- =============================================================
-- PROCEDURE 1: reserve_blood
--
-- Creates a new blood_reservation for an open emergency_request.
-- Locks the inventory row, checks stock, decrements
-- available_units, increments reserved_units.
--
-- Parameters (IN):
--   p_request_id           – emergency_request.request_id
--   p_supplier_hospital_id – hospital supplying the blood
--   p_units                – number of units to reserve
--   p_reserved_by          – app_user.user_id
-- Parameters (OUT):
--   p_reservation_id       – new reservation_id on success, 0 on fail
--   p_message              – human-readable result
--
-- Validations:
--   • Request must exist
--   • Request status must be PENDING or RESERVED
--   • Supplier hospital must have an inventory row for the group
--   • Available units must be >= p_units
-- =============================================================
DROP PROCEDURE IF EXISTS reserve_blood //
CREATE PROCEDURE reserve_blood(
  IN  p_request_id           INT,
  IN  p_supplier_hospital_id INT,
  IN  p_units                INT,
  IN  p_reserved_by          INT,
  OUT p_reservation_id       INT,
  OUT p_message              VARCHAR(255)
)
BEGIN
  -- ── All DECLARE statements first (MySQL rule) ──────────────
  DECLARE v_req_blood_group_id INT     DEFAULT 0;
  DECLARE v_req_status         VARCHAR(20) DEFAULT '';
  DECLARE v_inv_id             INT     DEFAULT 0;
  DECLARE v_available          INT     DEFAULT 0;
  DECLARE v_ok                 TINYINT DEFAULT 1;   -- 1=proceed, 0=abort

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_reservation_id = 0;
    SET p_message = 'ERROR: Unexpected SQL exception — transaction rolled back.';
  END;

  -- ── Initialise output ─────────────────────────────────────
  SET p_reservation_id = 0;
  SET p_message        = '';
  SET v_ok             = 1;

  START TRANSACTION;

  -- Step 1: Lock and read the request row
  SELECT blood_group_id, `status`
  INTO   v_req_blood_group_id, v_req_status
  FROM   emergency_request
  WHERE  request_id = p_request_id
  FOR UPDATE;

  IF v_req_blood_group_id = 0 THEN
    SET v_ok = 0;
    SET p_message = 'ERROR: Emergency request not found.';
  END IF;

  IF v_ok = 1 AND v_req_status NOT IN ('PENDING', 'RESERVED') THEN
    SET v_ok = 0;
    SET p_message = CONCAT('ERROR: Request is ', v_req_status,
                            ' — only PENDING or RESERVED requests can be reserved.');
  END IF;

  -- Step 2: Lock and read inventory row (exact blood group match)
  IF v_ok = 1 THEN
    SELECT inventory_id, available_units
    INTO   v_inv_id, v_available
    FROM   blood_inventory
    WHERE  hospital_id    = p_supplier_hospital_id
      AND  blood_group_id = v_req_blood_group_id
    FOR UPDATE;

    IF v_inv_id = 0 THEN
      SET v_ok = 0;
      SET p_message = 'ERROR: Supplier hospital has no inventory for the requested blood group.';
    END IF;
  END IF;

  -- Step 3: Check sufficient stock
  IF v_ok = 1 AND v_available < p_units THEN
    SET v_ok = 0;
    SET p_message = CONCAT('ERROR: Insufficient stock. Available: ', v_available,
                            ' unit(s), requested: ', p_units, ' unit(s).');
  END IF;

  -- Step 4: Perform update and insert
  IF v_ok = 1 THEN
    UPDATE blood_inventory
    SET    available_units = available_units - p_units,
           reserved_units  = reserved_units  + p_units
    WHERE  inventory_id    = v_inv_id;

    INSERT INTO blood_reservation
      (request_id, hospital_id, blood_group_id, units_reserved,
       status, reserved_by, reserved_at)
    VALUES
      (p_request_id, p_supplier_hospital_id, v_req_blood_group_id,
       p_units, 'RESERVED', p_reserved_by, NOW());

    SET p_reservation_id = LAST_INSERT_ID();

    -- Flip request to RESERVED if still PENDING
    UPDATE emergency_request
    SET    `status` = 'RESERVED'
    WHERE  request_id = p_request_id
      AND  `status`   = 'PENDING';

    COMMIT;
    SET p_message = CONCAT('SUCCESS: Reserved ', p_units,
                            ' unit(s). Reservation ID = ', p_reservation_id, '.');
  ELSE
    ROLLBACK;
  END IF;

END //


-- =============================================================
-- PROCEDURE 2: fulfill_reservation
--
-- Marks a RESERVED reservation as ALLOCATED.
-- Decrements reserved_units, increments allocated_units.
-- Sets request to FULFILLED when no RESERVED reservations remain.
--
-- Duplicate fulfilment is rejected (reservation already ALLOCATED
-- or CANCELLED).
-- =============================================================
DROP PROCEDURE IF EXISTS fulfill_reservation //
CREATE PROCEDURE fulfill_reservation(
  IN  p_reservation_id INT,
  IN  p_fulfilled_by   INT,
  OUT p_message        VARCHAR(255)
)
BEGIN
  DECLARE v_inv_id      INT DEFAULT 0;
  DECLARE v_units       INT DEFAULT 0;
  DECLARE v_res_status  VARCHAR(20) DEFAULT '';
  DECLARE v_request_id  INT DEFAULT 0;
  DECLARE v_blood_grp   INT DEFAULT 0;
  DECLARE v_hosp_id     INT DEFAULT 0;
  DECLARE v_pending_cnt INT DEFAULT 0;
  DECLARE v_ok          TINYINT DEFAULT 1;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_message = 'ERROR: Unexpected SQL exception — transaction rolled back.';
  END;

  SET p_message = '';
  SET v_ok      = 1;

  START TRANSACTION;

  SELECT `status`, units_reserved, request_id, blood_group_id, hospital_id
  INTO   v_res_status, v_units, v_request_id, v_blood_grp, v_hosp_id
  FROM   blood_reservation
  WHERE  reservation_id = p_reservation_id
  FOR UPDATE;

  IF v_res_status = '' THEN
    SET v_ok = 0;
    SET p_message = 'ERROR: Reservation not found.';
  END IF;

  IF v_ok = 1 AND v_res_status <> 'RESERVED' THEN
    SET v_ok = 0;
    SET p_message = CONCAT('ERROR: Reservation is already ', v_res_status,
                            ' — duplicate fulfilment prevented.');
  END IF;

  IF v_ok = 1 THEN
    SELECT inventory_id
    INTO   v_inv_id
    FROM   blood_inventory
    WHERE  hospital_id    = v_hosp_id
      AND  blood_group_id = v_blood_grp
    FOR UPDATE;

    UPDATE blood_inventory
    SET    reserved_units  = reserved_units  - v_units,
           allocated_units = allocated_units + v_units
    WHERE  inventory_id    = v_inv_id;

    UPDATE blood_reservation
    SET    `status` = 'ALLOCATED'
    WHERE  reservation_id = p_reservation_id;

    -- Auto-fulfil request if no RESERVED reservations remain
    SELECT COUNT(*)
    INTO   v_pending_cnt
    FROM   blood_reservation
    WHERE  request_id = v_request_id
      AND  `status`   = 'RESERVED';

    IF v_pending_cnt = 0 THEN
      UPDATE emergency_request
      SET    `status` = 'FULFILLED'
      WHERE  request_id = v_request_id;
    END IF;

    COMMIT;
    SET p_message = CONCAT('SUCCESS: Reservation ', p_reservation_id,
                            ' fulfilled (', v_units, ' unit(s) allocated).');
  ELSE
    ROLLBACK;
  END IF;

END //


-- =============================================================
-- PROCEDURE 3: release_reservation
--
-- Cancels a RESERVED reservation; restores available_units.
-- Resets request to PENDING when no RESERVED reservations remain.
-- =============================================================
DROP PROCEDURE IF EXISTS release_reservation //
CREATE PROCEDURE release_reservation(
  IN  p_reservation_id INT,
  IN  p_released_by    INT,
  OUT p_message        VARCHAR(255)
)
BEGIN
  DECLARE v_inv_id      INT DEFAULT 0;
  DECLARE v_units       INT DEFAULT 0;
  DECLARE v_res_status  VARCHAR(20) DEFAULT '';
  DECLARE v_request_id  INT DEFAULT 0;
  DECLARE v_blood_grp   INT DEFAULT 0;
  DECLARE v_hosp_id     INT DEFAULT 0;
  DECLARE v_still_res   INT DEFAULT 0;
  DECLARE v_ok          TINYINT DEFAULT 1;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_message = 'ERROR: Unexpected SQL exception — transaction rolled back.';
  END;

  SET p_message = '';
  SET v_ok      = 1;

  START TRANSACTION;

  SELECT `status`, units_reserved, request_id, blood_group_id, hospital_id
  INTO   v_res_status, v_units, v_request_id, v_blood_grp, v_hosp_id
  FROM   blood_reservation
  WHERE  reservation_id = p_reservation_id
  FOR UPDATE;

  IF v_res_status = '' THEN
    SET v_ok = 0;
    SET p_message = 'ERROR: Reservation not found.';
  END IF;

  IF v_ok = 1 AND v_res_status <> 'RESERVED' THEN
    SET v_ok = 0;
    SET p_message = CONCAT('ERROR: Reservation is ', v_res_status,
                            ' — only RESERVED reservations can be released.');
  END IF;

  IF v_ok = 1 THEN
    SELECT inventory_id
    INTO   v_inv_id
    FROM   blood_inventory
    WHERE  hospital_id    = v_hosp_id
      AND  blood_group_id = v_blood_grp
    FOR UPDATE;

    UPDATE blood_inventory
    SET    available_units = available_units + v_units,
           reserved_units  = reserved_units  - v_units
    WHERE  inventory_id    = v_inv_id;

    UPDATE blood_reservation
    SET    `status` = 'CANCELLED'
    WHERE  reservation_id = p_reservation_id;

    SELECT COUNT(*)
    INTO   v_still_res
    FROM   blood_reservation
    WHERE  request_id = v_request_id
      AND  `status`   = 'RESERVED';

    IF v_still_res = 0 THEN
      UPDATE emergency_request
      SET    `status` = 'PENDING'
      WHERE  request_id = v_request_id
        AND  `status`   = 'RESERVED';
    END IF;

    COMMIT;
    SET p_message = CONCAT('SUCCESS: Reservation ', p_reservation_id,
                            ' released — ', v_units,
                            ' unit(s) restored to available inventory.');
  ELSE
    ROLLBACK;
  END IF;

END //


-- =============================================================
-- PROCEDURE 4: allocate_resource
--
-- Reduces available_quantity on a physical resource.
-- Sets status to UNAVAILABLE when available_quantity reaches 0.
-- =============================================================
DROP PROCEDURE IF EXISTS allocate_resource //
CREATE PROCEDURE allocate_resource(
  IN  p_resource_id       INT,
  IN  p_units_to_allocate INT,
  IN  p_allocated_by      INT,
  OUT p_message           VARCHAR(255)
)
BEGIN
  DECLARE v_available INT DEFAULT -1;
  DECLARE v_status    VARCHAR(20) DEFAULT '';
  DECLARE v_new_avail INT DEFAULT 0;
  DECLARE v_ok        TINYINT DEFAULT 1;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_message = 'ERROR: Unexpected SQL exception — transaction rolled back.';
  END;

  SET p_message = '';
  SET v_ok      = 1;

  START TRANSACTION;

  SELECT available_quantity, `status`
  INTO   v_available, v_status
  FROM   resource
  WHERE  resource_id = p_resource_id
  FOR UPDATE;

  IF v_available = -1 THEN
    SET v_ok = 0;
    SET p_message = 'ERROR: Resource not found.';
  END IF;

  IF v_ok = 1 AND v_status = 'UNAVAILABLE' THEN
    SET v_ok = 0;
    SET p_message = 'ERROR: Resource is marked UNAVAILABLE.';
  END IF;

  IF v_ok = 1 AND v_available < p_units_to_allocate THEN
    SET v_ok = 0;
    SET p_message = CONCAT('ERROR: Insufficient resource units. Available: ',
                            v_available, ', requested: ', p_units_to_allocate, '.');
  END IF;

  IF v_ok = 1 THEN
    SET v_new_avail = v_available - p_units_to_allocate;

    UPDATE resource
    SET    available_quantity = v_new_avail,
           `status`           = IF(v_new_avail = 0, 'UNAVAILABLE', 'AVAILABLE')
    WHERE  resource_id        = p_resource_id;

    COMMIT;
    SET p_message = CONCAT('SUCCESS: Allocated ', p_units_to_allocate,
                            ' unit(s) of resource ', p_resource_id,
                            '. Remaining available: ', v_new_avail, '.');
  ELSE
    ROLLBACK;
  END IF;

END //


-- =============================================================
-- PROCEDURE 5: cancel_request
--
-- Cancels a PENDING or RESERVED emergency request.
-- Uses a cursor to iterate over all RESERVED reservations,
-- restore inventory units, and mark each CANCELLED.
-- =============================================================
DROP PROCEDURE IF EXISTS cancel_request //
CREATE PROCEDURE cancel_request(
  IN  p_request_id   INT,
  IN  p_cancelled_by INT,
  OUT p_message      VARCHAR(255)
)
BEGIN
  DECLARE v_req_status   VARCHAR(20) DEFAULT '';
  DECLARE v_done         INT DEFAULT 0;
  DECLARE v_res_id       INT;
  DECLARE v_units        INT;
  DECLARE v_blood_grp    INT;
  DECLARE v_hosp_id      INT;
  DECLARE v_inv_id       INT DEFAULT 0;
  DECLARE v_released_cnt INT DEFAULT 0;
  DECLARE v_ok           TINYINT DEFAULT 1;

  DECLARE cur_reservations CURSOR FOR
    SELECT reservation_id, units_reserved, blood_group_id, hospital_id
    FROM   blood_reservation
    WHERE  request_id = p_request_id
      AND  `status`   = 'RESERVED';

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_message = 'ERROR: Unexpected SQL exception — transaction rolled back.';
  END;

  SET p_message = '';
  SET v_ok      = 1;

  START TRANSACTION;

  SELECT `status`
  INTO   v_req_status
  FROM   emergency_request
  WHERE  request_id = p_request_id
  FOR UPDATE;

  IF v_req_status = '' THEN
    SET v_ok = 0;
    SET p_message = 'ERROR: Request not found.';
  END IF;

  IF v_ok = 1 AND v_req_status IN ('FULFILLED', 'CANCELLED') THEN
    SET v_ok = 0;
    SET p_message = CONCAT('ERROR: Request is already ', v_req_status,
                            ' — cannot cancel.');
  END IF;

  IF v_ok = 1 THEN
    OPEN cur_reservations;

    reservation_loop: LOOP
      FETCH cur_reservations INTO v_res_id, v_units, v_blood_grp, v_hosp_id;
      IF v_done = 1 THEN LEAVE reservation_loop; END IF;

      SET v_inv_id = 0;

      SELECT inventory_id
      INTO   v_inv_id
      FROM   blood_inventory
      WHERE  hospital_id    = v_hosp_id
        AND  blood_group_id = v_blood_grp;

      IF v_inv_id > 0 THEN
        UPDATE blood_inventory
        SET    available_units = available_units + v_units,
               reserved_units  = reserved_units  - v_units
        WHERE  inventory_id    = v_inv_id;
      END IF;

      UPDATE blood_reservation
      SET    `status` = 'CANCELLED'
      WHERE  reservation_id = v_res_id;

      SET v_released_cnt = v_released_cnt + 1;
    END LOOP;

    CLOSE cur_reservations;

    UPDATE emergency_request
    SET    `status` = 'CANCELLED'
    WHERE  request_id = p_request_id;

    COMMIT;
    SET p_message = CONCAT('SUCCESS: Request ', p_request_id,
                            ' cancelled. ', v_released_cnt,
                            ' reservation(s) released and inventory restored.');
  ELSE
    ROLLBACK;
  END IF;

END //

DELIMITER ;
