-- =============================================================
-- FILE   : 06_seed_data.sql
-- PURPOSE: Seed all tables with enough data to demonstrate
--          the full application.
-- SAFE   : Uses INSERT IGNORE on lookup tables and
--          INSERT ... ON DUPLICATE KEY UPDATE / IGNORE on
--          tables with UNIQUE / PK constraints so the script
--          can be re-run without creating duplicate records.
-- RUN    : After 05_stored_procedure_and_function.sql
--          and before 07_transactions.sql / 08_trigger.sql
-- =============================================================
USE emergency_system;

-- ─────────────────────────────────────────────────────────────
-- Temporarily disable FK checks so we can truncate / re-seed
-- safely during development.  Re-enabled at end of script.
-- ─────────────────────────────────────────────────────────────
SET FOREIGN_KEY_CHECKS = 0;

-- =============================================================
-- 1. BLOOD GROUPS  (8 standard ABO + Rh groups)
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
-- 2. BLOOD COMPATIBILITY  (donor_group_id → recipient_group_id)
--    Rules:
--      O-  (8) → all groups (universal donor)
--      O+  (7) → O+, A+, B+, AB+
--      A-  (2) → A+, A-, AB+, AB-
--      A+  (1) → A+, AB+
--      B-  (4) → B+, B-, AB+, AB-
--      B+  (3) → B+, AB+
--      AB- (6) → AB+, AB-
--      AB+ (5) → AB+  (universal recipient — receives all)
-- =============================================================
INSERT IGNORE INTO blood_compatibility (donor_group_id, recipient_group_id) VALUES
  -- O- is universal donor: can donate to everyone (8 rows)
  (8, 1), (8, 2), (8, 3), (8, 4), (8, 5), (8, 6), (8, 7), (8, 8),
  -- O+ can donate to O+, A+, B+, AB+
  (7, 7), (7, 1), (7, 3), (7, 5),
  -- A- can donate to A-, A+, AB-, AB+
  (2, 2), (2, 1), (2, 6), (2, 5),
  -- A+ can donate to A+, AB+
  (1, 1), (1, 5),
  -- B- can donate to B-, B+, AB-, AB+
  (4, 4), (4, 3), (4, 6), (4, 5),
  -- B+ can donate to B+, AB+
  (3, 3), (3, 5),
  -- AB- can donate to AB-, AB+
  (6, 6), (6, 5),
  -- AB+ can donate to AB+ only
  (5, 5);

-- =============================================================
-- 3. HOSPITALS  (5 hospitals across different cities)
-- =============================================================
INSERT IGNORE INTO hospital
  (hospital_id, hospital_name, address, city, phone, hospital_type, status)
VALUES
  (1, 'City General Hospital',   '12 MG Road',          'Bangalore', '080-22001100', 'General',    'ACTIVE'),
  (2, 'Apollo Blood Bank',       '45 Anna Salai',        'Chennai',   '044-28001200', 'Blood Bank', 'ACTIVE'),
  (3, 'Metro Trauma Centre',     '7 Rajpath',            'Delhi',     '011-23001300', 'Trauma',     'ACTIVE'),
  (4, 'Sunrise Medical Centre',  '89 FC Road',           'Pune',      '020-24001400', 'General',    'ACTIVE'),
  (5, 'Lifeline Hospital',       '33 Park Street',       'Kolkata',   '033-25001500', 'General',    'INACTIVE');

-- =============================================================
-- 4. APP USERS
--    Password for ALL accounts: Password@123
--    Hashed with bcrypt, cost factor 12.
--    Hash: $2b$12$K9L1mV5XjZL.VqY8f4CcOeNZrLQ1gP2hBwDmUKf7xTtM8sA3nIv4u
--    (Pre-generated offline; verified with bcryptjs)
-- =============================================================
INSERT IGNORE INTO app_user
  (user_id, full_name, email, password_hash, role, account_status, hospital_id)
VALUES
  -- ADMIN: not tied to any hospital
  (1,
   'Admin User',
   'admin@bloodclock.com',
   '$2b$12$K9L1mV5XjZL.VqY8f4CcOeNZrLQ1gP2hBwDmUKf7xTtM8sA3nIv4u',
   'ADMIN',
   'ACTIVE',
   NULL),

  -- HOSPITAL_STAFF: one per active hospital
  (2,
   'Priya Sharma',
   'priya@citygeneral.com',
   '$2b$12$K9L1mV5XjZL.VqY8f4CcOeNZrLQ1gP2hBwDmUKf7xTtM8sA3nIv4u',
   'HOSPITAL_STAFF',
   'ACTIVE',
   1),

  (3,
   'Rajan Nair',
   'rajan@apollobb.com',
   '$2b$12$K9L1mV5XjZL.VqY8f4CcOeNZrLQ1gP2hBwDmUKf7xTtM8sA3nIv4u',
   'HOSPITAL_STAFF',
   'ACTIVE',
   2),

  (4,
   'Anjali Mehta',
   'anjali@metrotrauma.com',
   '$2b$12$K9L1mV5XjZL.VqY8f4CcOeNZrLQ1gP2hBwDmUKf7xTtM8sA3nIv4u',
   'HOSPITAL_STAFF',
   'ACTIVE',
   3),

  (5,
   'Suresh Pillai',
   'suresh@sunrisemc.com',
   '$2b$12$K9L1mV5XjZL.VqY8f4CcOeNZrLQ1gP2hBwDmUKf7xTtM8sA3nIv4u',
   'HOSPITAL_STAFF',
   'ACTIVE',
   4);

-- =============================================================
-- 5. DONORS  (10 donors across hospitals and blood groups)
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
--    One row per (hospital, blood_group) pair.
--    Hospitals 1–4 stocked; hospital 5 (INACTIVE) omitted.
--    Units: available | reserved | allocated
-- =============================================================
INSERT IGNORE INTO blood_inventory
  (inventory_id, hospital_id, blood_group_id,
   available_units, reserved_units, allocated_units)
VALUES
  -- Hospital 1: City General (Bangalore)
  ( 1, 1, 1, 15, 0, 2),   -- A+
  ( 2, 1, 2,  8, 0, 1),   -- A-
  ( 3, 1, 3, 20, 0, 0),   -- B+
  ( 4, 1, 7, 25, 0, 3),   -- O+
  ( 5, 1, 8, 10, 0, 1),   -- O-

  -- Hospital 2: Apollo Blood Bank (Chennai)
  ( 6, 2, 1, 30, 2, 0),   -- A+   (2 already reserved)
  ( 7, 2, 5, 12, 0, 0),   -- AB+
  ( 8, 2, 7, 18, 3, 0),   -- O+   (3 already reserved)
  ( 9, 2, 8, 22, 0, 0),   -- O-

  -- Hospital 3: Metro Trauma (Delhi)
  (10, 3, 3, 10, 0, 1),   -- B+
  (11, 3, 4,  5, 0, 0),   -- B-
  (12, 3, 7, 14, 1, 0),   -- O+   (1 already reserved)
  (13, 3, 8,  9, 0, 0),   -- O-

  -- Hospital 4: Sunrise Medical (Pune)
  (14, 4, 1,  6, 0, 0),   -- A+
  (15, 4, 2,  3, 0, 0),   -- A-
  (16, 4, 3,  8, 0, 0),   -- B+
  (17, 4, 6,  4, 0, 0),   -- AB-
  (18, 4, 7, 11, 0, 0),   -- O+
  (19, 4, 8,  7, 0, 0),   -- O-
  (20, 4, 5,  5, 0, 0);   -- AB+

-- =============================================================
-- 7. RESOURCES
--    Types: ICU Bed, Ventilator, Ambulance
--    Hospitals 1–4 each have resources.
-- =============================================================
INSERT IGNORE INTO resource
  (resource_id, hospital_id, resource_name, resource_type,
   total_quantity, available_quantity, status)
VALUES
  -- Hospital 1
  ( 1, 1, 'ICU Bed Unit A',      'ICU Bed',    10,  3, 'AVAILABLE'),
  ( 2, 1, 'Adult Ventilator',    'Ventilator',  6,  2, 'AVAILABLE'),
  ( 3, 1, 'Ambulance Unit 1',    'Ambulance',   3,  1, 'AVAILABLE'),

  -- Hospital 2
  ( 4, 2, 'ICU Bed Wing B',      'ICU Bed',    15,  8, 'AVAILABLE'),
  ( 5, 2, 'Paediatric Ventilator','Ventilator',  4,  4, 'AVAILABLE'),
  ( 6, 2, 'Ambulance Unit 2',    'Ambulance',   2,  2, 'AVAILABLE'),

  -- Hospital 3
  ( 7, 3, 'Trauma ICU Beds',     'ICU Bed',    20,  5, 'AVAILABLE'),
  ( 8, 3, 'High-Flow Ventilator','Ventilator',  8,  0, 'UNAVAILABLE'),
  ( 9, 3, 'Ambulance Unit 3',    'Ambulance',   4,  3, 'AVAILABLE'),

  -- Hospital 4
  (10, 4, 'General ICU Beds',    'ICU Bed',     8,  6, 'AVAILABLE'),
  (11, 4, 'Standard Ventilator', 'Ventilator',  3,  1, 'AVAILABLE'),
  (12, 4, 'Ambulance Unit 4',    'Ambulance',   2,  0, 'UNAVAILABLE'),

  -- Extra resources for demo
  (13, 1, 'Neonatal ICU Bed',    'ICU Bed',     4,  4, 'AVAILABLE'),
  (14, 2, 'Transport Ambulance', 'Ambulance',   3,  3, 'AVAILABLE'),
  (15, 3, 'Mobile ICU',          'ICU Bed',     2,  2, 'AVAILABLE');

-- =============================================================
-- 8. EMERGENCY REQUESTS
--    Covers all 4 priorities, both PENDING and in-progress
--    statuses, and multiple hospitals.
--    required_by is set relative to a fixed demo date so the
--    calculate_emergency_priority() function also fires the
--    overdue bonus for CRITICAL requests.
-- =============================================================
INSERT IGNORE INTO emergency_request
  (request_id, hospital_id, blood_group_id, quantity_required,
   priority, status, created_at, required_by, created_by)
VALUES
  -- CRITICAL: overdue (required_by in the past) → urgency score = 5
  (1, 3, 8, 5, 'CRITICAL', 'PENDING',
   '2026-11-10 08:00:00', '2026-11-10 10:00:00', 4),

  -- HIGH: required soon
  (2, 1, 1, 3, 'HIGH', 'PENDING',
   '2026-11-11 09:00:00', '2026-11-11 15:00:00', 2),

  -- MEDIUM: active
  (3, 4, 3, 4, 'MEDIUM', 'PENDING',
   '2026-11-11 10:00:00', '2026-11-12 10:00:00', 5),

  -- LOW: for planning purposes
  (4, 2, 7, 2, 'LOW', 'PENDING',
   '2026-11-11 11:00:00', '2026-11-13 11:00:00', 3),

  -- RESERVED: already has a reservation
  (5, 3, 7, 3, 'HIGH', 'RESERVED',
   '2026-11-10 07:00:00', '2026-11-11 12:00:00', 4),

  -- FULFILLED: completed request
  (6, 1, 1, 2, 'MEDIUM', 'FULFILLED',
   '2026-11-09 06:00:00', '2026-11-10 06:00:00', 2),

  -- CANCELLED: for demo of cancel flow
  (7, 4, 5, 1, 'LOW', 'CANCELLED',
   '2026-11-08 05:00:00', '2026-11-09 05:00:00', 5),

  -- Another CRITICAL PENDING request to test multi-reservation
  (8, 1, 8, 4, 'CRITICAL', 'PENDING',
   '2026-11-11 06:00:00', '2026-11-11 14:00:00', 2);

-- =============================================================
-- 9. BLOOD RESERVATIONS
--    Only for requests that are RESERVED or FULFILLED.
--    INSERT IGNORE to avoid duplicate PK on re-run.
-- =============================================================
INSERT IGNORE INTO blood_reservation
  (reservation_id, request_id, hospital_id, blood_group_id,
   units_reserved, status, reserved_by, reserved_at)
VALUES
  -- Request 5 (RESERVED): 3 units O+ from Hospital 2
  (1, 5, 2, 7, 3, 'RESERVED',  3, '2026-11-10 07:30:00'),

  -- Request 6 (FULFILLED): 2 units A+ from Hospital 1 → ALLOCATED
  (2, 6, 1, 1, 2, 'ALLOCATED', 2, '2026-11-09 06:30:00'),

  -- Request 2 (PENDING → partial reservation pre-seeded): 2 units A+ from Hospital 2
  (3, 2, 2, 1, 2, 'RESERVED',  2, '2026-11-11 09:15:00'),

  -- Cancelled reservation for request 7
  (4, 7, 4, 5, 1, 'CANCELLED', 5, '2026-11-08 05:15:00');

-- ─────────────────────────────────────────────────────────────
-- Re-enable FK checks
-- ─────────────────────────────────────────────────────────────
SET FOREIGN_KEY_CHECKS = 1;

-- =============================================================
-- VERIFICATION QUERIES  (run manually to confirm seed data)
-- =============================================================
-- SELECT COUNT(*) AS blood_groups    FROM blood_group;        -- expect 8
-- SELECT COUNT(*) AS compatibility   FROM blood_compatibility; -- expect 28
-- SELECT COUNT(*) AS hospitals       FROM hospital;            -- expect 5
-- SELECT COUNT(*) AS users           FROM app_user;            -- expect 5
-- SELECT COUNT(*) AS donors          FROM donor;               -- expect 10
-- SELECT COUNT(*) AS inventory_rows  FROM blood_inventory;     -- expect 20
-- SELECT COUNT(*) AS resources       FROM resource;            -- expect 15
-- SELECT COUNT(*) AS requests        FROM emergency_request;   -- expect 8
-- SELECT COUNT(*) AS reservations    FROM blood_reservation;   -- expect 4
