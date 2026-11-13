
-- =============================================================
-- FILE   : 07_transactions.sql
-- PURPOSE: Transactional stored procedures for blood reservations
--          and emergency resource allocation.
--
-- PROCEDURES:
--   1. reserve_blood
--   2. fulfill_reservation
--   3. release_reservation
--   4. allocate_resource_for_request
--   5. cancel_request
--   6. cancel_resource_request
--
-- DESIGN:
--   - Parent requests are locked before child records.
--   - Inventory rows are locked before quantity changes.
--   - Every procedure uses explicit transaction handling.
--   - Errors roll back the complete transaction.
--   - Released/cancelled records preserve allocation history.
--
-- REQUIREMENTS:
--   - MySQL 8.0+
--   - Existing tables and columns must match the project schema.
-- =============================================================

USE emergency_system;

DELIMITER //


-- =============================================================
-- PROCEDURE 1: reserve_blood
--
-- Reserves compatible blood from one supplier inventory row.
-- Exact blood-group matches are preferred.
-- The actual donor blood group is stored in blood_reservation.
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
    DECLARE v_req_blood_group_id INT DEFAULT 0;
    DECLARE v_req_status         VARCHAR(20) DEFAULT '';
    DECLARE v_qty_required       INT DEFAULT 0;

    DECLARE v_already_reserved   INT DEFAULT 0;
    DECLARE v_already_allocated  INT DEFAULT 0;
    DECLARE v_remaining          INT DEFAULT 0;

    DECLARE v_inv_id             INT DEFAULT 0;
    DECLARE v_donor_group_id     INT DEFAULT 0;
    DECLARE v_available          INT DEFAULT 0;

    DECLARE v_request_missing    TINYINT DEFAULT 0;
    DECLARE v_inventory_missing  TINYINT DEFAULT 0;
    DECLARE v_ok                 TINYINT DEFAULT 1;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_reservation_id = 0;
        SET p_message =
            'ERROR: Blood reservation failed. Transaction rolled back.';
    END;

    SET p_reservation_id = 0;
    SET p_message = '';
    SET v_ok = 1;

    -- Validate inputs before starting the transaction.
    IF p_units IS NULL OR p_units <= 0 THEN
        SET v_ok = 0;
        SET p_message =
            'ERROR: Reservation quantity must be greater than zero.';
    END IF;

    IF p_request_id IS NULL OR p_supplier_hospital_id IS NULL THEN
        SET v_ok = 0;
        SET p_message =
            'ERROR: Request ID and supplier hospital ID are required.';
    END IF;

    IF v_ok = 1 THEN

        START TRANSACTION;

        -- Step 1: Lock the emergency request.
        BEGIN
            DECLARE CONTINUE HANDLER FOR NOT FOUND
                SET v_request_missing = 1;

            SELECT blood_group_id, `status`, quantity_required
            INTO v_req_blood_group_id, v_req_status, v_qty_required
            FROM emergency_request
            WHERE request_id = p_request_id
            FOR UPDATE;
        END;

        IF v_request_missing = 1 THEN
            SET v_ok = 0;
            SET p_message = 'ERROR: Emergency request not found.';
        END IF;

        -- Step 2: Validate request status.
        IF v_ok = 1
           AND v_req_status NOT IN ('PENDING', 'RESERVED') THEN

            SET v_ok = 0;
            SET p_message = CONCAT(
                'ERROR: Request is ', v_req_status,
                '. Only PENDING or RESERVED requests can receive reservations.'
            );
        END IF;

        -- Step 3: Calculate quantities already reserved and allocated.
        IF v_ok = 1 THEN

            SELECT
                COALESCE(SUM(
                    CASE WHEN `status` = 'RESERVED'
                         THEN units_reserved ELSE 0 END
                ), 0),
                COALESCE(SUM(
                    CASE WHEN `status` = 'ALLOCATED'
                         THEN units_reserved ELSE 0 END
                ), 0)
            INTO v_already_reserved, v_already_allocated
            FROM blood_reservation
            WHERE request_id = p_request_id;

            SET v_remaining =
                v_qty_required
                - v_already_reserved
                - v_already_allocated;

            IF v_remaining <= 0 THEN
                SET v_ok = 0;
                SET p_message =
                    'ERROR: Emergency request is already fully covered.';

            ELSEIF p_units > v_remaining THEN
                SET v_ok = 0;
                SET p_message = CONCAT(
                    'ERROR: Reservation exceeds remaining request quantity. ',
                    'Remaining: ', v_remaining,
                    ', requested: ', p_units, '.'
                );
            END IF;

        END IF;

        -- Step 4: Find one compatible donor inventory row.
        -- Prefer exact blood-group match, then greatest available stock.
        IF v_ok = 1 THEN

            BEGIN
                DECLARE CONTINUE HANDLER FOR NOT FOUND
                    SET v_inventory_missing = 1;

                SELECT
                    bi.inventory_id,
                    bi.blood_group_id,
                    bi.available_units
                INTO
                    v_inv_id,
                    v_donor_group_id,
                    v_available
                FROM blood_inventory bi
                JOIN blood_compatibility bc
                    ON bc.donor_group_id = bi.blood_group_id
                JOIN hospital h
                    ON h.hospital_id = bi.hospital_id
                WHERE bi.hospital_id = p_supplier_hospital_id
                  AND bc.recipient_group_id = v_req_blood_group_id
                  AND bi.available_units >= p_units
                  AND h.status = 'ACTIVE'
                ORDER BY
                    (bi.blood_group_id = v_req_blood_group_id) DESC,
                    bi.available_units DESC,
                    bi.blood_group_id
                LIMIT 1
                FOR UPDATE;
            END;

            IF v_inventory_missing = 1 THEN
                SET v_ok = 0;
                SET p_message =
                    'ERROR: No active supplier inventory has enough compatible blood.';
            END IF;

        END IF;

        -- Step 5: Update inventory and create reservation.
        IF v_ok = 1 THEN

            UPDATE blood_inventory
            SET available_units = available_units - p_units,
                reserved_units = reserved_units + p_units
            WHERE inventory_id = v_inv_id
              AND available_units >= p_units;

            IF ROW_COUNT() <> 1 THEN
                SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT =
                        'Blood inventory changed or insufficient stock.';
            END IF;

            INSERT INTO blood_reservation (
                request_id,
                hospital_id,
                blood_group_id,
                units_reserved,
                `status`,
                reserved_by,
                reserved_at
            )
            VALUES (
                p_request_id,
                p_supplier_hospital_id,
                v_donor_group_id,
                p_units,
                'RESERVED',
                p_reserved_by,
                NOW()
            );

            SET p_reservation_id = LAST_INSERT_ID();

            UPDATE emergency_request
            SET `status` = 'RESERVED'
            WHERE request_id = p_request_id;

            COMMIT;

            SET p_message = CONCAT(
                'SUCCESS: Reserved ', p_units,
                ' unit(s) of donor blood group ID ',
                v_donor_group_id,
                '. Reservation ID = ', p_reservation_id, '.'
            );

        ELSE
            ROLLBACK;
        END IF;

    END IF;

END //


-- =============================================================
-- PROCEDURE 2: fulfill_reservation
--
-- Converts a RESERVED reservation into ALLOCATED.
-- Updates inventory and recalculates emergency request status.
-- =============================================================

DROP PROCEDURE IF EXISTS fulfill_reservation //

CREATE PROCEDURE fulfill_reservation(
    IN  p_reservation_id INT,
    IN  p_fulfilled_by   INT,
    OUT p_message        VARCHAR(255)
)
BEGIN
    DECLARE v_request_id       INT DEFAULT 0;
    DECLARE v_req_status       VARCHAR(20) DEFAULT '';
    DECLARE v_qty_required     INT DEFAULT 0;

    DECLARE v_res_status       VARCHAR(20) DEFAULT '';
    DECLARE v_units            INT DEFAULT 0;
    DECLARE v_blood_grp        INT DEFAULT 0;
    DECLARE v_hosp_id          INT DEFAULT 0;

    DECLARE v_inv_id           INT DEFAULT 0;
    DECLARE v_reserved_stock   INT DEFAULT 0;

    DECLARE v_allocated_total  INT DEFAULT 0;
    DECLARE v_reserved_total   INT DEFAULT 0;
    DECLARE v_new_req_status   VARCHAR(20) DEFAULT '';

    DECLARE v_lookup_missing   TINYINT DEFAULT 0;
    DECLARE v_request_missing  TINYINT DEFAULT 0;
    DECLARE v_res_missing      TINYINT DEFAULT 0;
    DECLARE v_inv_missing      TINYINT DEFAULT 0;
    DECLARE v_ok               TINYINT DEFAULT 1;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_message =
            'ERROR: Fulfilment failed. Transaction rolled back.';
    END;

    SET p_message = '';
    SET v_ok = 1;

    START TRANSACTION;

    -- Step 1: Find parent request ID.
    -- This lookup is non-locking; the parent is locked next.
    BEGIN
        DECLARE CONTINUE HANDLER FOR NOT FOUND
            SET v_lookup_missing = 1;

        SELECT request_id
        INTO v_request_id
        FROM blood_reservation
        WHERE reservation_id = p_reservation_id;
    END;

    IF v_lookup_missing = 1 THEN
        SET v_ok = 0;
        SET p_message = 'ERROR: Reservation not found.';
    END IF;

    -- Step 2: Lock parent request first.
    IF v_ok = 1 THEN

        BEGIN
            DECLARE CONTINUE HANDLER FOR NOT FOUND
                SET v_request_missing = 1;

            SELECT `status`, quantity_required
            INTO v_req_status, v_qty_required
            FROM emergency_request
            WHERE request_id = v_request_id
            FOR UPDATE;
        END;

        IF v_request_missing = 1 THEN
            SET v_ok = 0;
            SET p_message = 'ERROR: Parent emergency request not found.';
        END IF;

    END IF;

    IF v_ok = 1
       AND v_req_status NOT IN ('PENDING', 'RESERVED') THEN

        SET v_ok = 0;
        SET p_message = CONCAT(
            'ERROR: Request is ', v_req_status,
            '. Only PENDING or RESERVED requests can be fulfilled.'
        );
    END IF;

    -- Step 3: Lock reservation.
    IF v_ok = 1 THEN

        BEGIN
            DECLARE CONTINUE HANDLER FOR NOT FOUND
                SET v_res_missing = 1;

            SELECT
                `status`,
                units_reserved,
                blood_group_id,
                hospital_id
            INTO
                v_res_status,
                v_units,
                v_blood_grp,
                v_hosp_id
            FROM blood_reservation
            WHERE reservation_id = p_reservation_id
            FOR UPDATE;
        END;

        IF v_res_missing = 1 THEN
            SET v_ok = 0;
            SET p_message = 'ERROR: Reservation no longer exists.';
        END IF;

    END IF;

    IF v_ok = 1 AND v_res_status <> 'RESERVED' THEN
        SET v_ok = 0;
        SET p_message = CONCAT(
            'ERROR: Reservation is ', v_res_status,
            '. Only RESERVED reservations can be fulfilled.'
        );
    END IF;

    -- Step 4: Lock and validate inventory.
    IF v_ok = 1 THEN

        BEGIN
            DECLARE CONTINUE HANDLER FOR NOT FOUND
                SET v_inv_missing = 1;

            SELECT inventory_id, reserved_units
            INTO v_inv_id, v_reserved_stock
            FROM blood_inventory
            WHERE hospital_id = v_hosp_id
              AND blood_group_id = v_blood_grp
            FOR UPDATE;
        END;

        IF v_inv_missing = 1 THEN
            SET v_ok = 0;
            SET p_message =
                'ERROR: Inventory row for this reservation was not found.';

        ELSEIF v_reserved_stock < v_units THEN
            SET v_ok = 0;
            SET p_message =
                'ERROR: Reserved inventory is lower than the reservation quantity.';
        END IF;

    END IF;

    -- Step 5: Convert reserved units into allocated units.
    IF v_ok = 1 THEN

        UPDATE blood_inventory
        SET reserved_units = reserved_units - v_units,
            allocated_units = allocated_units + v_units
        WHERE inventory_id = v_inv_id
          AND reserved_units >= v_units;

        IF ROW_COUNT() <> 1 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT =
                    'Blood inventory changed during fulfilment.';
        END IF;

        UPDATE blood_reservation
        SET `status` = 'ALLOCATED'
        WHERE reservation_id = p_reservation_id
          AND `status` = 'RESERVED';

        IF ROW_COUNT() <> 1 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT =
                    'Reservation status changed during fulfilment.';
        END IF;

        -- Step 6: Recalculate request status.
        SELECT
            COALESCE(SUM(
                CASE WHEN `status` = 'ALLOCATED'
                     THEN units_reserved ELSE 0 END
            ), 0),
            COALESCE(SUM(
                CASE WHEN `status` = 'RESERVED'
                     THEN units_reserved ELSE 0 END
            ), 0)
        INTO v_allocated_total, v_reserved_total
        FROM blood_reservation
        WHERE request_id = v_request_id;

        IF v_allocated_total >= v_qty_required THEN
            SET v_new_req_status = 'FULFILLED';

        ELSEIF v_reserved_total > 0 THEN
            SET v_new_req_status = 'RESERVED';

        ELSE
            SET v_new_req_status = 'PENDING';
        END IF;

        UPDATE emergency_request
        SET `status` = v_new_req_status
        WHERE request_id = v_request_id;

        COMMIT;

        SET p_message = CONCAT(
            'SUCCESS: Reservation ', p_reservation_id,
            ' fulfilled. ', v_units,
            ' unit(s) allocated. Request status: ',
            v_new_req_status, '.'
        );

    ELSE
        ROLLBACK;
    END IF;

END //


-- =============================================================
-- PROCEDURE 3: release_reservation
--
-- Cancels a RESERVED reservation and restores its units
-- to available inventory. ALLOCATED reservations cannot
-- be released using this procedure.
-- =============================================================

DROP PROCEDURE IF EXISTS release_reservation //

CREATE PROCEDURE release_reservation(
    IN  p_reservation_id INT,
    IN  p_released_by    INT,
    OUT p_message        VARCHAR(255)
)
BEGIN
    DECLARE v_request_id       INT DEFAULT 0;
    DECLARE v_req_status       VARCHAR(20) DEFAULT '';
    DECLARE v_qty_required     INT DEFAULT 0;

    DECLARE v_res_status       VARCHAR(20) DEFAULT '';
    DECLARE v_units            INT DEFAULT 0;
    DECLARE v_blood_grp        INT DEFAULT 0;
    DECLARE v_hosp_id          INT DEFAULT 0;

    DECLARE v_inv_id           INT DEFAULT 0;
    DECLARE v_reserved_stock   INT DEFAULT 0;

    DECLARE v_allocated_total  INT DEFAULT 0;
    DECLARE v_reserved_total   INT DEFAULT 0;
    DECLARE v_new_req_status   VARCHAR(20) DEFAULT '';

    DECLARE v_lookup_missing   TINYINT DEFAULT 0;
    DECLARE v_request_missing  TINYINT DEFAULT 0;
    DECLARE v_res_missing      TINYINT DEFAULT 0;
    DECLARE v_inv_missing      TINYINT DEFAULT 0;
    DECLARE v_ok               TINYINT DEFAULT 1;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_message =
            'ERROR: Reservation release failed. Transaction rolled back.';
    END;

    SET p_message = '';
    SET v_ok = 1;

    START TRANSACTION;

    -- Step 1: Find parent request ID.
    BEGIN
        DECLARE CONTINUE HANDLER FOR NOT FOUND
            SET v_lookup_missing = 1;

        SELECT request_id
        INTO v_request_id
        FROM blood_reservation
        WHERE reservation_id = p_reservation_id;
    END;

    IF v_lookup_missing = 1 THEN
        SET v_ok = 0;
        SET p_message = 'ERROR: Reservation not found.';
    END IF;

    -- Step 2: Lock parent request.
    IF v_ok = 1 THEN

        BEGIN
            DECLARE CONTINUE HANDLER FOR NOT FOUND
                SET v_request_missing = 1;

            SELECT `status`, quantity_required
            INTO v_req_status, v_qty_required
            FROM emergency_request
            WHERE request_id = v_request_id
            FOR UPDATE;
        END;

        IF v_request_missing = 1 THEN
            SET v_ok = 0;
            SET p_message = 'ERROR: Parent emergency request not found.';
        END IF;

    END IF;

    IF v_ok = 1
       AND v_req_status NOT IN ('PENDING', 'RESERVED') THEN

        SET v_ok = 0;
        SET p_message = CONCAT(
            'ERROR: Request is ', v_req_status,
            '. Only PENDING or RESERVED requests can release reservations.'
        );
    END IF;

    -- Step 3: Lock reservation.
    IF v_ok = 1 THEN

        BEGIN
            DECLARE CONTINUE HANDLER FOR NOT FOUND
                SET v_res_missing = 1;

            SELECT
                `status`,
                units_reserved,
                blood_group_id,
                hospital_id
            INTO
                v_res_status,
                v_units,
                v_blood_grp,
                v_hosp_id
            FROM blood_reservation
            WHERE reservation_id = p_reservation_id
            FOR UPDATE;
        END;

        IF v_res_missing = 1 THEN
            SET v_ok = 0;
            SET p_message = 'ERROR: Reservation no longer exists.';
        END IF;

    END IF;

    IF v_ok = 1 AND v_res_status <> 'RESERVED' THEN
        SET v_ok = 0;
        SET p_message = CONCAT(
            'ERROR: Reservation is ', v_res_status,
            '. Only RESERVED reservations can be released.'
        );
    END IF;

    -- Step 4: Lock and validate inventory.
    IF v_ok = 1 THEN

        BEGIN
            DECLARE CONTINUE HANDLER FOR NOT FOUND
                SET v_inv_missing = 1;

            SELECT inventory_id, reserved_units
            INTO v_inv_id, v_reserved_stock
            FROM blood_inventory
            WHERE hospital_id = v_hosp_id
              AND blood_group_id = v_blood_grp
            FOR UPDATE;
        END;

        IF v_inv_missing = 1 THEN
            SET v_ok = 0;
            SET p_message =
                'ERROR: Inventory row for this reservation was not found.';

        ELSEIF v_reserved_stock < v_units THEN
            SET v_ok = 0;
            SET p_message =
                'ERROR: Reserved inventory is lower than the reservation quantity.';
        END IF;

    END IF;

    -- Step 5: Restore inventory and cancel reservation.
    IF v_ok = 1 THEN

        UPDATE blood_inventory
        SET available_units = available_units + v_units,
            reserved_units = reserved_units - v_units
        WHERE inventory_id = v_inv_id
          AND reserved_units >= v_units;

        IF ROW_COUNT() <> 1 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT =
                    'Blood inventory changed during release.';
        END IF;

        UPDATE blood_reservation
        SET `status` = 'CANCELLED'
        WHERE reservation_id = p_reservation_id
          AND `status` = 'RESERVED';

        IF ROW_COUNT() <> 1 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT =
                    'Reservation status changed during release.';
        END IF;

        -- Step 6: Recalculate request status.
        SELECT
            COALESCE(SUM(
                CASE WHEN `status` = 'ALLOCATED'
                     THEN units_reserved ELSE 0 END
            ), 0),
            COALESCE(SUM(
                CASE WHEN `status` = 'RESERVED'
                     THEN units_reserved ELSE 0 END
            ), 0)
        INTO v_allocated_total, v_reserved_total
        FROM blood_reservation
        WHERE request_id = v_request_id;

        IF v_allocated_total >= v_qty_required THEN
            SET v_new_req_status = 'FULFILLED';

        ELSEIF v_reserved_total > 0 THEN
            SET v_new_req_status = 'RESERVED';

        ELSE
            SET v_new_req_status = 'PENDING';
        END IF;

        UPDATE emergency_request
        SET `status` = v_new_req_status
        WHERE request_id = v_request_id;

        COMMIT;

        SET p_message = CONCAT(
            'SUCCESS: Reservation ', p_reservation_id,
            ' released. ', v_units,
            ' unit(s) restored. Request status: ',
            v_new_req_status, '.'
        );

    ELSE
        ROLLBACK;
    END IF;

END //


-- =============================================================
-- PROCEDURE 4: allocate_resource_for_request
--
-- Allocates a resource from a supplier hospital.
-- Supports partial fulfilment through multiple allocations.
-- =============================================================

DROP PROCEDURE IF EXISTS allocate_resource_for_request //

CREATE PROCEDURE allocate_resource_for_request(
    IN  p_resource_request_id INT,
    IN  p_resource_id         INT,
    IN  p_units_to_allocate   INT,
    IN  p_allocated_by        INT,
    OUT p_message             VARCHAR(255)
)
BEGIN
    DECLARE v_req_resource_type VARCHAR(50) DEFAULT '';
    DECLARE v_req_status        VARCHAR(30) DEFAULT '';
    DECLARE v_qty_required      INT DEFAULT 0;

    DECLARE v_req_missing       TINYINT DEFAULT 0;
    DECLARE v_res_missing       TINYINT DEFAULT 0;

    DECLARE v_res_resource_type VARCHAR(50) DEFAULT '';
    DECLARE v_res_available     INT DEFAULT -1;
    DECLARE v_res_status        VARCHAR(20) DEFAULT '';
    DECLARE v_hosp_status       VARCHAR(20) DEFAULT '';

    DECLARE v_already_allocated INT DEFAULT 0;
    DECLARE v_new_total         INT DEFAULT 0;
    DECLARE v_new_res_avail     INT DEFAULT 0;
    DECLARE v_new_req_status    VARCHAR(30) DEFAULT '';
    DECLARE v_ok                TINYINT DEFAULT 1;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_message =
            'ERROR: Resource allocation failed. Transaction rolled back.';
    END;

    SET p_message = '';
    SET v_ok = 1;

    IF p_units_to_allocate IS NULL OR p_units_to_allocate <= 0 THEN
        SET v_ok = 0;
        SET p_message =
            'ERROR: Allocation quantity must be greater than zero.';
    END IF;

    IF p_resource_request_id IS NULL OR p_resource_id IS NULL THEN
        SET v_ok = 0;
        SET p_message =
            'ERROR: Resource request ID and resource ID are required.';
    END IF;

    IF v_ok = 1 THEN

        START TRANSACTION;

        -- Step 1: Lock parent resource request.
        BEGIN
            DECLARE CONTINUE HANDLER FOR NOT FOUND
                SET v_req_missing = 1;

            SELECT resource_type, `status`, quantity_required
            INTO v_req_resource_type, v_req_status, v_qty_required
            FROM resource_request
            WHERE resource_request_id = p_resource_request_id
            FOR UPDATE;
        END;

        IF v_req_missing = 1 THEN
            SET v_ok = 0;
            SET p_message = 'ERROR: Resource request not found.';
        END IF;

        -- Step 2: Validate request status.
        IF v_ok = 1
           AND v_req_status IN ('CANCELLED', 'FULFILLED') THEN

            SET v_ok = 0;
            SET p_message = CONCAT(
                'ERROR: Resource request is ', v_req_status,
                ' and cannot receive more allocations.'
            );
        END IF;

        -- Step 3: Lock supplier resource and read hospital status.
        IF v_ok = 1 THEN

            BEGIN
                DECLARE CONTINUE HANDLER FOR NOT FOUND
                    SET v_res_missing = 1;

                SELECT
                    r.resource_type,
                    r.available_quantity,
                    r.`status`,
                    h.`status`
                INTO
                    v_res_resource_type,
                    v_res_available,
                    v_res_status,
                    v_hosp_status
                FROM resource r
                JOIN hospital h
                    ON h.hospital_id = r.hospital_id
                WHERE r.resource_id = p_resource_id
                FOR UPDATE;
            END;

            IF v_res_missing = 1 THEN
                SET v_ok = 0;
                SET p_message =
                    'ERROR: Resource or its supplier hospital was not found.';
            END IF;

        END IF;

        -- Step 4: Validate resource type.
        IF v_ok = 1
           AND v_res_resource_type <> v_req_resource_type THEN

            SET v_ok = 0;
            SET p_message = CONCAT(
                'ERROR: Resource type mismatch. Required: ',
                v_req_resource_type,
                ', supplied: ', v_res_resource_type, '.'
            );
        END IF;

        -- Step 5: Validate supplier hospital and resource status.
        IF v_ok = 1 AND v_hosp_status <> 'ACTIVE' THEN
            SET v_ok = 0;
            SET p_message =
                'ERROR: Supplier hospital is not ACTIVE.';
        END IF;

        IF v_ok = 1 AND v_res_status <> 'AVAILABLE' THEN
            SET v_ok = 0;
            SET p_message =
                'ERROR: Supplier resource is marked UNAVAILABLE.';
        END IF;

        -- Step 6: Validate stock.
        IF v_ok = 1
           AND v_res_available < p_units_to_allocate THEN

            SET v_ok = 0;
            SET p_message = CONCAT(
                'ERROR: Insufficient resource stock. Available: ',
                v_res_available,
                ', requested: ', p_units_to_allocate, '.'
            );
        END IF;

        -- Step 7: Calculate existing active allocations.
        IF v_ok = 1 THEN

            SELECT COALESCE(SUM(quantity_allocated), 0)
            INTO v_already_allocated
            FROM resource_allocation
            WHERE resource_request_id = p_resource_request_id
              AND `status` = 'ALLOCATED';

            SET v_new_total =
                v_already_allocated + p_units_to_allocate;

            IF v_new_total > v_qty_required THEN
                SET v_ok = 0;
                SET p_message = CONCAT(
                    'ERROR: Allocation exceeds requested quantity. ',
                    'Already allocated: ', v_already_allocated,
                    ', attempting: ', p_units_to_allocate,
                    ', required: ', v_qty_required, '.'
                );
            END IF;

        END IF;

        -- Step 8: Insert allocation and reduce resource inventory.
        IF v_ok = 1 THEN

            INSERT INTO resource_allocation (
                resource_request_id,
                resource_id,
                quantity_allocated,
                `status`,
                allocated_by,
                allocated_at,
                released_by,
                released_at
            )
            VALUES (
                p_resource_request_id,
                p_resource_id,
                p_units_to_allocate,
                'ALLOCATED',
                p_allocated_by,
                NOW(),
                NULL,
                NULL
            );

            SET v_new_res_avail =
                v_res_available - p_units_to_allocate;

            UPDATE resource
            SET available_quantity = v_new_res_avail,
                `status` = IF(
                    v_new_res_avail = 0,
                    'UNAVAILABLE',
                    'AVAILABLE'
                )
            WHERE resource_id = p_resource_id
              AND available_quantity >= p_units_to_allocate;

            IF ROW_COUNT() <> 1 THEN
                SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT =
                        'Resource inventory changed during allocation.';
            END IF;

            -- Step 9: Update request status.
            IF v_new_total < v_qty_required THEN
                SET v_new_req_status = 'PARTIALLY_FULFILLED';
            ELSE
                SET v_new_req_status = 'FULFILLED';
            END IF;

            UPDATE resource_request
            SET `status` = v_new_req_status
            WHERE resource_request_id = p_resource_request_id;

            COMMIT;

            SET p_message = CONCAT(
                'SUCCESS: Allocated ', p_units_to_allocate,
                ' unit(s) of resource ', p_resource_id,
                ' to request ', p_resource_request_id,
                '. Request status: ', v_new_req_status, '.'
            );

        ELSE
            ROLLBACK;
        END IF;

    END IF;

END //


-- =============================================================
-- PROCEDURE 5: cancel_request
--
-- Cancels a blood emergency request.
--
-- POLICY:
--   - RESERVED reservations are cancelled.
--   - Their inventory is restored.
--   - ALLOCATED reservations are preserved unchanged.
--   - FULFILLED requests cannot be cancelled.
--   - The emergency request is marked CANCELLED.
-- =============================================================

DROP PROCEDURE IF EXISTS cancel_request //

CREATE PROCEDURE cancel_request(
    IN  p_request_id   INT,
    IN  p_cancelled_by INT,
    OUT p_message      VARCHAR(255)
)
BEGIN
    DECLARE v_req_status     VARCHAR(20) DEFAULT '';
    DECLARE v_req_missing    TINYINT DEFAULT 0;

    DECLARE v_done           TINYINT DEFAULT 0;
    DECLARE v_res_id         INT;
    DECLARE v_units          INT;
    DECLARE v_blood_grp      INT;
    DECLARE v_hosp_id        INT;

    DECLARE v_inv_id         INT DEFAULT 0;
    DECLARE v_reserved_stock INT DEFAULT 0;
    DECLARE v_inv_missing    TINYINT DEFAULT 0;

    DECLARE v_released_cnt   INT DEFAULT 0;
    DECLARE v_ok             TINYINT DEFAULT 1;

    -- Cursor processes only RESERVED reservations.
    -- Consistent ordering reduces inconsistent inventory lock order.
    DECLARE cur_reservations CURSOR FOR
        SELECT
            reservation_id,
            units_reserved,
            blood_group_id,
            hospital_id
        FROM blood_reservation
        WHERE request_id = p_request_id
          AND `status` = 'RESERVED'
        ORDER BY hospital_id, blood_group_id, reservation_id;

    -- This handler is exclusively for cursor FETCH exhaustion.
    DECLARE CONTINUE HANDLER FOR NOT FOUND
        SET v_done = 1;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_message =
            'ERROR: Blood request cancellation failed. Transaction rolled back.';
    END;

    SET p_message = '';
    SET v_ok = 1;

    START TRANSACTION;

    -- Step 1: Lock parent request using a scoped handler.
    BEGIN
        DECLARE CONTINUE HANDLER FOR NOT FOUND
            SET v_req_missing = 1;

        SELECT `status`
        INTO v_req_status
        FROM emergency_request
        WHERE request_id = p_request_id
        FOR UPDATE;
    END;

    IF v_req_missing = 1 THEN
        SET v_ok = 0;
        SET p_message = 'ERROR: Emergency request not found.';
    END IF;

    IF v_ok = 1
       AND v_req_status IN ('FULFILLED', 'CANCELLED') THEN

        SET v_ok = 0;
        SET p_message = CONCAT(
            'ERROR: Request is already ', v_req_status,
            ' and cannot be cancelled.'
        );
    END IF;

    -- Step 2: Release all RESERVED reservations.
    IF v_ok = 1 THEN

        OPEN cur_reservations;

        reservation_loop: LOOP

            FETCH cur_reservations
            INTO v_res_id, v_units, v_blood_grp, v_hosp_id;

            IF v_done = 1 THEN
                LEAVE reservation_loop;
            END IF;

            SET v_inv_id = 0;
            SET v_reserved_stock = 0;
            SET v_inv_missing = 0;

            -- Scoped handler prevents inventory lookup failure
            -- from being mistaken for cursor exhaustion.
            BEGIN
                DECLARE CONTINUE HANDLER FOR NOT FOUND
                    SET v_inv_missing = 1;

                SELECT inventory_id, reserved_units
                INTO v_inv_id, v_reserved_stock
                FROM blood_inventory
                WHERE hospital_id = v_hosp_id
                  AND blood_group_id = v_blood_grp
                FOR UPDATE;
            END;

            IF v_inv_missing = 1 THEN
                SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT =
                        'Inventory row for a reservation was not found.';
            END IF;

            IF v_reserved_stock < v_units THEN
                SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT =
                        'Reserved inventory is lower than reservation quantity.';
            END IF;

            -- Restore inventory.
            UPDATE blood_inventory
            SET available_units = available_units + v_units,
                reserved_units = reserved_units - v_units
            WHERE inventory_id = v_inv_id
              AND reserved_units >= v_units;

            IF ROW_COUNT() <> 1 THEN
                SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT =
                        'Inventory changed during request cancellation.';
            END IF;

            -- Preserve reservation row as historical data.
            UPDATE blood_reservation
            SET `status` = 'CANCELLED'
            WHERE reservation_id = v_res_id
              AND `status` = 'RESERVED';

            IF ROW_COUNT() <> 1 THEN
                SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT =
                        'Reservation status changed during cancellation.';
            END IF;

            SET v_released_cnt = v_released_cnt + 1;

        END LOOP;

        CLOSE cur_reservations;

        -- Step 3: Preserve ALLOCATED reservations and cancel request.
        UPDATE emergency_request
        SET `status` = 'CANCELLED'
        WHERE request_id = p_request_id;

        COMMIT;

        SET p_message = CONCAT(
            'SUCCESS: Request ', p_request_id,
            ' cancelled. ', v_released_cnt,
            ' RESERVED reservation(s) released. ',
            'Previously ALLOCATED reservations were preserved.'
        );

    ELSE
        ROLLBACK;
    END IF;

END //


-- =============================================================
-- PROCEDURE 6: cancel_resource_request
--
-- Releases every active resource allocation belonging to a
-- resource request, restores supplier inventory, and preserves
-- allocation history by changing ALLOCATED to RELEASED.
--
-- POLICY:
--   - PENDING requests can be cancelled.
--   - PARTIALLY_FULFILLED requests can be cancelled.
--   - FULFILLED requests cannot be cancelled.
--   - Already CANCELLED requests cannot be cancelled again.
-- =============================================================

DROP PROCEDURE IF EXISTS cancel_resource_request //

CREATE PROCEDURE cancel_resource_request(
    IN  p_resource_request_id INT,
    IN  p_cancelled_by        INT,
    OUT p_message             VARCHAR(255)
)
BEGIN
    DECLARE v_req_status       VARCHAR(30) DEFAULT '';
    DECLARE v_req_missing      TINYINT DEFAULT 0;

    DECLARE v_done             TINYINT DEFAULT 0;
    DECLARE v_released_cnt     INT DEFAULT 0;

    DECLARE v_alloc_id         INT;
    DECLARE v_res_id           INT;
    DECLARE v_qty              INT;

    DECLARE v_res_avail        INT DEFAULT -1;
    DECLARE v_total_quantity   INT DEFAULT 0;
    DECLARE v_new_res_avail    INT DEFAULT 0;
    DECLARE v_resource_missing TINYINT DEFAULT 0;

    -- Cursor processes active allocations only.
    -- Consistent ordering reduces inconsistent resource lock order.
    DECLARE cur_allocs CURSOR FOR
        SELECT
            allocation_id,
            resource_id,
            quantity_allocated
        FROM resource_allocation
        WHERE resource_request_id = p_resource_request_id
          AND `status` = 'ALLOCATED'
        ORDER BY resource_id, allocation_id;

    -- This handler is exclusively for cursor FETCH exhaustion.
    DECLARE CONTINUE HANDLER FOR NOT FOUND
        SET v_done = 1;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_message =
            'ERROR: Resource request cancellation failed. Transaction rolled back.';
    END;

    SET p_message = '';

    START TRANSACTION;

    -- Step 1: Lock parent request.
    BEGIN
        DECLARE CONTINUE HANDLER FOR NOT FOUND
            SET v_req_missing = 1;

        SELECT `status`
        INTO v_req_status
        FROM resource_request
        WHERE resource_request_id = p_resource_request_id
        FOR UPDATE;
    END;

    IF v_req_missing = 1 THEN

        SET p_message = 'ERROR: Resource request not found.';
        ROLLBACK;

    ELSEIF v_req_status = 'CANCELLED' THEN

        SET p_message =
            'ERROR: Resource request is already CANCELLED.';
        ROLLBACK;

    ELSEIF v_req_status = 'FULFILLED' THEN

        SET p_message =
            'ERROR: A FULFILLED resource request cannot be cancelled.';
        ROLLBACK;

    ELSE

        -- Step 2: Release all active allocations.
        OPEN cur_allocs;

        release_loop: LOOP

            FETCH cur_allocs
            INTO v_alloc_id, v_res_id, v_qty;

            IF v_done = 1 THEN
                LEAVE release_loop;
            END IF;

            SET v_res_avail = -1;
            SET v_total_quantity = 0;
            SET v_resource_missing = 0;

            -- Scoped handler: only this resource lookup.
            BEGIN
                DECLARE CONTINUE HANDLER FOR NOT FOUND
                    SET v_resource_missing = 1;

                SELECT available_quantity, total_quantity
                INTO v_res_avail, v_total_quantity
                FROM resource
                WHERE resource_id = v_res_id
                FOR UPDATE;
            END;

            IF v_resource_missing = 1 THEN
                SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT =
                        'Resource referenced by allocation was not found.';
            END IF;

            SET v_new_res_avail = v_res_avail + v_qty;

            IF v_new_res_avail > v_total_quantity THEN
                SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT =
                        'Restoring allocation would exceed resource total quantity.';
            END IF;

            -- Step 3: Restore supplier inventory.
            UPDATE resource
            SET available_quantity = v_new_res_avail,
                `status` = IF(
                    v_new_res_avail > 0,
                    'AVAILABLE',
                    'UNAVAILABLE'
                )
            WHERE resource_id = v_res_id;

            IF ROW_COUNT() <> 1 THEN
                SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT =
                        'Resource inventory could not be restored.';
            END IF;

            -- Step 4: Preserve allocation history.
            UPDATE resource_allocation
            SET `status` = 'RELEASED',
                released_by = p_cancelled_by,
                released_at = NOW()
            WHERE allocation_id = v_alloc_id
              AND `status` = 'ALLOCATED';

            IF ROW_COUNT() <> 1 THEN
                SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT =
                        'Allocation status changed during cancellation.';
            END IF;

            SET v_released_cnt = v_released_cnt + 1;

        END LOOP;

        CLOSE cur_allocs;

        -- Step 5: Mark parent request cancelled.
        UPDATE resource_request
        SET `status` = 'CANCELLED'
        WHERE resource_request_id = p_resource_request_id;

        COMMIT;

        SET p_message = CONCAT(
            'SUCCESS: Resource request ', p_resource_request_id,
            ' cancelled. ', v_released_cnt,
            ' allocation(s) released and inventory restored.'
        );

    END IF;

END //


DELIMITER ;

-- =============================================================
-- END OF FILE
-- =============================================================
