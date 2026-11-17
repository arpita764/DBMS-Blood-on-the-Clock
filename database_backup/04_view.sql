-- =============================================================
-- MEMBER 2 – Advanced DB Feature: VIEW
-- available_blood_by_hospital
-- Powers the blood availability dashboard
-- =============================================================
USE emergency_system;

CREATE OR REPLACE VIEW available_blood_by_hospital AS
  SELECT
    h.hospital_id,
    h.hospital_name,
    h.city,
    bg.group_name     AS blood_group,
    bi.available_units,
    bi.reserved_units,
    bi.last_updated,
    h.status          AS hospital_status
  FROM blood_inventory bi
  JOIN hospital    h  ON h.hospital_id     = bi.hospital_id
  JOIN blood_group bg ON bg.blood_group_id = bi.blood_group_id
  WHERE h.status = 'ACTIVE'
  ORDER BY bi.available_units DESC;

-- Usage:
--   SELECT * FROM available_blood_by_hospital WHERE blood_group = 'O-';
--   SELECT * FROM available_blood_by_hospital WHERE city = 'Bangalore';
