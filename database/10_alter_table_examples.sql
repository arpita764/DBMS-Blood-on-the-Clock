-- =============================================================
-- FILE   : 10_alter_table_examples.sql
-- PURPOSE: Demonstrate ALTER TABLE DDL.
--          The requirements ask for CREATE, ALTER and DROP.
--          CREATE is used throughout the schema files; DROP is
--          used for procedures/functions/triggers/temp tables.
--          This file adds ALTER TABLE to complete the set.
--
-- NOTE   : This is a ONE-TIME migration script. MySQL does not
--          support "ADD COLUMN IF NOT EXISTS", so re-running this
--          file will error on already-applied changes. Run it
--          AFTER 06_seed_data.sql and BEFORE first app use.
-- =============================================================
USE emergency_system;

-- 1. Add a contact email to hospital (used for alerts / lookup)
ALTER TABLE hospital
  ADD COLUMN contact_email VARCHAR(255) NULL AFTER phone;

-- 2. Add geolocation for proximity-based donor matching
ALTER TABLE hospital
  ADD COLUMN latitude  DECIMAL(10,7) NULL,
  ADD COLUMN longitude DECIMAL(10,7) NULL;

-- 3. Add medical-eligibility notes to donor
ALTER TABLE donor
  ADD COLUMN eligibility_notes VARCHAR(500) NULL AFTER last_donation_date;

-- 4. Add a cached, denormalised priority score to emergency_request.
--    This mirrors the stored function so dashboards avoid a per-row
--    function call. It is backfilled below.
ALTER TABLE emergency_request
  ADD COLUMN priority_score INT NULL;

-- 5. Add a unique index on the new email column (index via ALTER)
ALTER TABLE hospital
  ADD UNIQUE INDEX uq_hospital_email (contact_email);

-- 6. Widen resource_type to allow longer type descriptors
ALTER TABLE resource
  MODIFY COLUMN resource_type VARCHAR(80) NOT NULL;

-- 7. Add a table-level CHECK constraint via ALTER
ALTER TABLE emergency_request
  ADD CONSTRAINT chk_er_fulfilled_qty
  CHECK (status <> 'FULFILLED' OR quantity_required > 0);

-- 8. Backfill the cached priority_score using the stored function.
--    MySQL Workbench's "Safe Update Mode" blocks UPDATEs without a key
--    column in the WHERE clause, so we disable it for this statement.
SET SQL_SAFE_UPDATES = 0;
UPDATE emergency_request
SET priority_score = calculate_emergency_priority(priority, required_by);
SET SQL_SAFE_UPDATES = 1;

-- 9. Add a covering index for the dashboard's "pending by score" query
ALTER TABLE emergency_request
  ADD INDEX idx_er_pending_score (status, priority_score, required_by);

-- =============================================================
-- DROP demonstration (commented to avoid data loss during demo):
--   ALTER TABLE donor DROP COLUMN eligibility_notes;
-- DROP TABLE / DROP DATABASE are demonstrated in the other files.
-- =============================================================
