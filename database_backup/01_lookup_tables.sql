-- =============================================================
-- LOOKUP TABLES  (shared by both members)
-- blood_group + blood_compatibility
-- =============================================================
USE emergency_system;

CREATE TABLE blood_group (
  blood_group_id INT        AUTO_INCREMENT PRIMARY KEY,
  group_name     VARCHAR(3) NOT NULL UNIQUE   -- A+, A-, B+, B-, AB+, AB-, O+, O-
) ENGINE=InnoDB COMMENT='Blood group reference lookup';

-- M:N self-join: which blood group can donate to which
CREATE TABLE blood_compatibility (
  donor_group_id     INT NOT NULL,
  recipient_group_id INT NOT NULL,
  PRIMARY KEY (donor_group_id, recipient_group_id),
  CONSTRAINT fk_bc_donor     FOREIGN KEY (donor_group_id)     REFERENCES blood_group(blood_group_id),
  CONSTRAINT fk_bc_recipient FOREIGN KEY (recipient_group_id) REFERENCES blood_group(blood_group_id)
) ENGINE=InnoDB COMMENT='M:N blood compatibility (donor -> recipient)';
