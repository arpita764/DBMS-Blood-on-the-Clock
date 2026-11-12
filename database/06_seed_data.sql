

-- =============================================================
-- FILE   : 06_seed_data.sql
-- PURPOSE: Insert demonstration data into all project tables.
-- SAFETY : Uses INSERT IGNORE to avoid duplicate primary/unique
--          key insertions. Resource stock is deducted only for
--          newly inserted active resource allocations.
-- NOTE   : Existing rows are not overwritten or updated.
--          This is an additive seed script, not a reset script.
-- RUN    : After 05_stored_procedure_and_function.sql
--          and before 07_transactions.sql / 08_trigger.sql
-- =============================================================
USE emergency_system;
-- =============================================================
-- 1. BLOOD GROUPS (8 standard ABO + Rh groups)
-- =============================================================
INSERT IGNORE INTO blood_group (blood_group_id, group_name) VALUES
  (1, 'A+'),
  (2, 'A-'),
  (3, 'B+'),
  (4, 'B-'),
  (5, 'AB+'),
  (6, 'AB-'),
  (7, 'O+'),
  (8, 'O-');

-- =============================================================
-- 2. BLOOD COMPATIBILITY
-- =============================================================
INSERT IGNORE INTO blood_compatibility
  (donor_group_id, recipient_group_id) VALUES
  (8, 1), (8, 2), (8, 3), (8, 4), (8, 5), (8, 6), (8, 7), (8, 8),
  (7, 7), (7, 1), (7, 3), (7, 5),
  (2, 2), (2, 1), (2, 6), (2, 5),
  (1, 1), (1, 5),
  (4, 4), (4, 3), (4, 6), (4, 5),
  (3, 3), (3, 5),
  (6, 6), (6, 5),
  (5, 5);

-- =============================================================
-- 3. HOSPITALS
-- =============================================================
INSERT IGNORE INTO hospital
  (hospital_id, hospital_name, address, city, phone, hospital_type, status)
VALUES
  (1, 'City General Hospital',   '12 MG Road',     'Bangalore', '080-22001100', 'General',    'ACTIVE'),
  (2, 'Apollo Blood Bank',       '45 Anna Salai',  'Chennai',   '044-28001200', 'Blood Bank', 'ACTIVE'),
  (3, 'Metro Trauma Centre',     '7 Rajpath',      'Delhi',     '011-23001300', 'Trauma',     'ACTIVE'),
  (4, 'Sunrise Medical Centre',  '89 FC Road',     'Pune',      '020-24001400', 'General',    'ACTIVE'),
  (5, 'Lifeline Hospital',       '33 Park Street', 'Kolkata',   '033-25001500', 'General',    'INACTIVE');

-- =============================================================
-- 4. APP USERS
-- Password for all accounts: Password@123
-- Hash: bcrypt, cost factor 12
-- =============================================================
INSERT IGNORE INTO app_user
  (user_id, full_name, email, password_hash, role, account_status, hospital_id)
VALUES
  (1, 'Admin User', 'admin@bloodclock.com',
   '$2b$12$n9sYLTEEH4rTLLcEEFexleH3kpjI6bvkUPzv3c0g4iJRCYRGId4hy',
   'ADMIN', 'ACTIVE', NULL),

  (2, 'Priya Sharma', 'priya@citygeneral.com',
   '$2b$12$n9sYLTEEH4rTLLcEEFexleH3kpjI6bvkUPzv3c0g4iJRCYRGId4hy',
   'HOSPITAL_STAFF', 'ACTIVE', 1),

  (3, 'Rajan Nair', 'rajan@apollobb.com',
   '$2b$12$n9sYLTEEH4rTLLcEEFexleH3kpjI6bvkUPzv3c0g4iJRCYRGId4hy',
   'HOSPITAL_STAFF', 'ACTIVE', 2),

  (4, 'Anjali Mehta', 'anjali@metrotrauma.com',
   '$2b$12$n9sYLTEEH4rTLLcEEFexleH3kpjI6bvkUPzv3c0g4iJRCYRGId4hy',
   'HOSPITAL_STAFF', 'ACTIVE', 3),

  (5, 'Suresh Pillai', 'suresh@sunrisemc.com',
   '$2b$12$n9sYLTEEH4rTLLcEEFexleH3kpjI6bvkUPzv3c0g4iJRCYRGId4hy',
   'HOSPITAL_STAFF', 'ACTIVE', 4);

-- =============================================================
-- 5. DONORS
-- =============================================================
INSERT IGNORE INTO donor
  (donor_id, donor_name, phone, city, blood_group_id, hospital_id,
   availability_status, last_donation_date)
VALUES
  (1,  'Arun Kumar',     '9876543210', 'Bangalore', 7, 1, 'AVAILABLE',   '2026-08-15'),
  (2,  'Meena Iyer',     '9765432109', 'Bangalore', 2, 1, 'AVAILABLE',   '2026-07-20'),
  (3,  'Vikram Singh',   '9654321098', 'Chennai',   8, 2, 'AVAILABLE',   '2026-09-01'),
  (4,  'Deepa Krishnan', '9543210987', 'Chennai',   5, 2, 'UNAVAILABLE', '2026-10-05'),
  (5,  'Rahul Gupta',    '9432109876', 'Delhi',     3, 3, 'AVAILABLE',   '2026-06-18'),
  (6,  'Sunita Patel',   '9321098765', 'Delhi',     1, 3, 'AVAILABLE',   '2026-09-22'),
  (7,  'Kiran Desai',    '9210987654', 'Pune',      4, 4, 'AVAILABLE',   '2026-08-30'),
  (8,  'Pooja Nair',     '9109876543', 'Pune',      6, 4, 'AVAILABLE',   '2026-07-11'),
  (9,  'Amit Joshi',     '9098765432', 'Bangalore', 7, 1, 'UNAVAILABLE', '2026-10-25'),
  (10, 'Latha Reddy',    '9876501234', 'Chennai',   8, 2, 'AVAILABLE',   '2026-05-14');



-- =============================================================
-- 6. BLOOD INVENTORY
-- Matches the reconciled demonstration dataset.
-- Units: available | reserved | allocated
-- Every reserved/allocated quantity has a matching reservation.
-- =============================================================

INSERT IGNORE INTO blood_inventory
    (inventory_id, hospital_id, blood_group_id,
     available_units, reserved_units, allocated_units)
VALUES
    -- Hospital 1: City General Hospital
    ( 1, 1, 1, 15, 0, 2),
    ( 2, 1, 2,  8, 0, 0),
    ( 3, 1, 3, 20, 0, 0),
    ( 4, 1, 7, 25, 0, 0),
    ( 5, 1, 8,  5, 5, 0),

    -- Hospital 2: Apollo Blood Bank
    ( 6, 2, 1, 32, 0, 0),
    ( 7, 2, 5, 12, 0, 0),
    ( 8, 2, 7, 21, 0, 0),
    ( 9, 2, 8, 22, 0, 0),

    -- Hospital 3: Metro Trauma Centre
    (10, 3, 3, 10, 0, 0),
    (11, 3, 4,  5, 0, 0),
    (12, 3, 7, 15, 0, 0),
    (13, 3, 8,  9, 0, 0),

    -- Hospital 4: Sunrise Medical Centre
    (14, 4, 1,  6, 0, 0),
    (15, 4, 2,  3, 0, 0),
    (16, 4, 3,  4, 0, 4),
    (17, 4, 6,  4, 0, 0),
    (18, 4, 7, 11, 0, 0),
    (19, 4, 8,  7, 0, 0),
    (20, 4, 5,  5, 0, 0);


-- =============================================================
-- 7. RESOURCE INVENTORY
-- Matches the currently verified resource records.
-- =============================================================

INSERT IGNORE INTO resource
    (resource_id, hospital_id, resource_name, resource_type,
     total_quantity, available_quantity, status)
VALUES
    ( 1, 1, 'ICU Bed Unit A',       'ICU Bed',    10, 3, 'AVAILABLE'),
    ( 2, 1, 'Adult Ventilator',     'Ventilator',  6, 2, 'AVAILABLE'),
    ( 3, 1, 'Ambulance Unit 1',     'Ambulance',   3, 1, 'AVAILABLE'),

    ( 4, 2, 'ICU Bed Wing B',       'ICU Bed',    15, 5, 'AVAILABLE'),
    ( 5, 2, 'Paediatric Ventilator','Ventilator',  4, 4, 'AVAILABLE'),
    ( 6, 2, 'Ambulance Unit 2',     'Ambulance',   2, 2, 'AVAILABLE'),

    ( 7, 3, 'Trauma ICU Beds',      'ICU Bed',    20, 5, 'AVAILABLE'),
    ( 8, 3, 'High-Flow Ventilator', 'Ventilator',  8, 0, 'UNAVAILABLE'),
    ( 9, 3, 'Ambulance Unit 3',     'Ambulance',   4, 3, 'AVAILABLE'),

    (10, 4, 'General ICU Beds',     'ICU Bed',     8, 6, 'AVAILABLE'),
    (11, 4, 'Standard Ventilator',  'Ventilator',  3, 1, 'AVAILABLE'),
    (12, 4, 'Ambulance Unit 4',     'Ambulance',   2, 0, 'UNAVAILABLE'),

    (13, 1, 'Neonatal ICU Bed',     'ICU Bed',     4, 4, 'AVAILABLE'),
    (14, 2, 'Transport Ambulance',  'Ambulance',   3, 3, 'AVAILABLE'),
    (15, 3, 'Mobile ICU',           'ICU Bed',     2, 2, 'AVAILABLE');


-- =============================================================
-- 8. EMERGENCY REQUESTS
-- =============================================================

INSERT IGNORE INTO emergency_request
    (request_id, hospital_id, blood_group_id, quantity_required,
     priority, status, created_at, required_by, created_by)
VALUES
    (1, 3, 8, 5, 'CRITICAL', 'RESERVED',
     '2026-11-10 08:00:00', '2026-11-10 10:00:00', 4),

    (2, 1, 1, 3, 'HIGH', 'CANCELLED',
     '2026-11-11 09:00:00', '2026-11-11 15:00:00', 2),

    (3, 4, 3, 4, 'MEDIUM', 'FULFILLED',
     '2026-11-11 10:00:00', '2026-11-12 10:00:00', 5),

    (4, 2, 7, 2, 'LOW', 'PENDING',
     '2026-11-11 11:00:00', '2026-11-13 11:00:00', 3),

    (5, 3, 7, 3, 'HIGH', 'PENDING',
     '2026-11-10 07:00:00', '2026-11-11 12:00:00', 4),

    (6, 1, 1, 2, 'MEDIUM', 'FULFILLED',
     '2026-11-09 06:00:00', '2026-11-10 06:00:00', 2),

    (7, 4, 5, 1, 'LOW', 'CANCELLED',
     '2026-11-08 05:00:00', '2026-11-09 05:00:00', 5),

    (8, 1, 8, 4, 'CRITICAL', 'PENDING',
     '2026-11-11 06:00:00', '2026-11-11 14:00:00', 2);


-- =============================================================
-- 9. BLOOD RESERVATIONS
-- =============================================================

INSERT IGNORE INTO blood_reservation
    (reservation_id, request_id, hospital_id, blood_group_id,
     units_reserved, status, reserved_by, reserved_at)
VALUES
    (1, 5, 2, 7, 3, 'CANCELLED',
     3, '2026-11-10 07:30:00'),

    (2, 6, 1, 1, 2, 'ALLOCATED',
     2, '2026-11-09 06:30:00'),

    (3, 2, 2, 1, 2, 'CANCELLED',
     2, '2026-11-11 09:15:00'),

    (4, 7, 4, 5, 1, 'CANCELLED',
     5, '2026-11-08 05:15:00'),

    (5, 3, 4, 3, 4, 'ALLOCATED',
     5, '2026-11-11 09:04:50'),

    (6, 1, 1, 8, 5, 'RESERVED',
     1, '2026-11-11 09:04:50'),

    (7, 1, 4, 8, 5, 'CANCELLED',
     1, '2026-11-11 09:04:50');


-- =============================================================
-- 10. RESOURCE REQUESTS
-- =============================================================

INSERT IGNORE INTO resource_request
    (resource_request_id, hospital_id, resource_type,
     quantity_required, priority, status,
     created_at, required_by, created_by)
VALUES
    (1, 3, 'ICU Bed',    3, 'HIGH',     'PENDING',
     '2026-11-10 08:00:00', '2026-11-11 08:00:00', 4),

    (2, 1, 'Ambulance',  4, 'CRITICAL', 'PARTIALLY_FULFILLED',
     '2026-11-10 09:00:00', '2026-11-10 12:00:00', 2),

    (3, 4, 'Ventilator', 3, 'MEDIUM',   'FULFILLED',
     '2026-11-10 10:00:00', '2026-11-11 10:00:00', 5),

    (4, 2, 'ICU Bed',    2, 'LOW',      'FULFILLED',
     '2026-11-10 11:00:00', '2026-11-12 11:00:00', 3),

    (5, 3, 'Ventilator', 2, 'LOW',      'CANCELLED',
     '2026-11-10 12:00:00', '2026-11-12 12:00:00', 4),

    (6, 1, 'ICU Bed',    5, 'HIGH',     'CANCELLED',
     '2026-11-10 13:00:00', '2026-11-11 13:00:00', 2);


-- =============================================================
-- 11. RESOURCE ALLOCATIONS
-- Insert allocations only once.
-- Reduce resource stock only for newly inserted ALLOCATED rows.
-- RELEASED allocations do not reduce stock.
-- =============================================================

DROP TEMPORARY TABLE IF EXISTS tmp_new_resource_allocations;

CREATE TEMPORARY TABLE tmp_new_resource_allocations AS
SELECT seed.allocation_id,
       seed.resource_id,
       seed.quantity_allocated,
       seed.status
FROM (
    SELECT 1 AS allocation_id, 2 AS resource_request_id,
           3 AS resource_id, 1 AS quantity_allocated,
           'ALLOCATED' AS status
    UNION ALL
    SELECT 2, 2, 6, 2, 'ALLOCATED'
    UNION ALL
    SELECT 3, 3, 5, 3, 'ALLOCATED'
    UNION ALL
    SELECT 4, 4, 4, 2, 'ALLOCATED'
    UNION ALL
    SELECT 5, 6, 1, 2, 'RELEASED'
) AS seed
LEFT JOIN resource_allocation existing
    ON existing.allocation_id = seed.allocation_id
WHERE existing.allocation_id IS NULL;

START TRANSACTION;

INSERT IGNORE INTO resource_allocation
    (allocation_id, resource_request_id, resource_id,
     quantity_allocated, status,
     allocated_by, allocated_at,
     released_by, released_at)
VALUES
    (1, 2, 3, 1, 'ALLOCATED',
     2, '2026-11-10 07:30:00', NULL, NULL),

    (2, 2, 6, 2, 'ALLOCATED',
     3, '2026-11-10 08:00:00', NULL, NULL),

    (3, 3, 5, 3, 'ALLOCATED',
     3, '2026-11-09 06:30:00', NULL, NULL),

    (4, 4, 4, 2, 'ALLOCATED',
     3, '2026-11-08 05:30:00', NULL, NULL),

    (5, 6, 1, 2, 'RELEASED',
     2, '2026-11-06 03:30:00',
     2, '2026-11-07 09:00:00');

-- Deduct stock only for allocations that were absent before
-- this run and are ALLOCATED.

UPDATE resource r
JOIN (
    SELECT resource_id,
           SUM(quantity_allocated) AS quantity_to_deduct
    FROM tmp_new_resource_allocations
    WHERE status = 'ALLOCATED'
    GROUP BY resource_id
) AS deductions
    ON deductions.resource_id = r.resource_id

-- Determine status using the original available quantity first.
SET r.status = CASE
        WHEN r.available_quantity = deductions.quantity_to_deduct
            THEN 'UNAVAILABLE'
        ELSE 'AVAILABLE'
    END,

    r.available_quantity =
        r.available_quantity - deductions.quantity_to_deduct

WHERE r.available_quantity >= deductions.quantity_to_deduct
  AND r.status = 'AVAILABLE';

COMMIT;

DROP TEMPORARY TABLE IF EXISTS tmp_new_resource_allocations;


