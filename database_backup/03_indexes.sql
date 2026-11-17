-- =============================================================
-- MEMBER 2 – Indexes on hospital, donor, resource tables
-- =============================================================
USE emergency_system;

-- Speed up city-based hospital lookups (dashboard, matching)
CREATE INDEX idx_hospital_city      ON hospital(city, status);

-- Speed up donor search by blood group and availability
CREATE INDEX idx_donor_group_avail  ON donor(blood_group_id, availability_status);

-- Speed up donor search by city (proximity matching)
CREATE INDEX idx_donor_city         ON donor(city);

-- Speed up resource lookup by type within a hospital
CREATE INDEX idx_resource_hosp_type ON resource(hospital_id, resource_type);
