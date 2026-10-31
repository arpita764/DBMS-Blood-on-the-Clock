-- =============================================================
-- MEMBER 2 – Hospital, App User, Donor, Resource tables
-- =============================================================
USE emergency_system;

CREATE TABLE hospital (
  hospital_id   INT          AUTO_INCREMENT PRIMARY KEY,
  hospital_name VARCHAR(150) NOT NULL,
  address       VARCHAR(255),
  city          VARCHAR(100) NOT NULL,
  phone         VARCHAR(20),
  hospital_type VARCHAR(50),                 -- General, Trauma, Blood Bank …
  status        ENUM('ACTIVE','INACTIVE') NOT NULL DEFAULT 'ACTIVE'
) ENGINE=InnoDB COMMENT='Registered hospitals / blood banks';

CREATE TABLE app_user (
  user_id        INT          AUTO_INCREMENT PRIMARY KEY,
  full_name      VARCHAR(150) NOT NULL,
  email          VARCHAR(255) NOT NULL UNIQUE,
  password_hash  VARCHAR(255) NOT NULL,
  role           ENUM('ADMIN','HOSPITAL_STAFF') NOT NULL,
  account_status ENUM('ACTIVE','DISABLED')       NOT NULL DEFAULT 'ACTIVE',
  hospital_id    INT NULL,
  CONSTRAINT fk_user_hospital FOREIGN KEY (hospital_id) REFERENCES hospital(hospital_id),
  CONSTRAINT chk_user_role    CHECK (role = 'ADMIN' OR hospital_id IS NOT NULL)
) ENGINE=InnoDB COMMENT='System users: Admin or Hospital Staff';

CREATE TABLE donor (
  donor_id            INT          AUTO_INCREMENT PRIMARY KEY,
  donor_name          VARCHAR(150) NOT NULL,
  phone               VARCHAR(20)  NOT NULL,
  city                VARCHAR(100) NOT NULL,
  blood_group_id      INT          NOT NULL,
  hospital_id         INT          NOT NULL,   -- registering hospital
  availability_status ENUM('AVAILABLE','UNAVAILABLE') NOT NULL DEFAULT 'AVAILABLE',
  last_donation_date  DATE NULL,
  CONSTRAINT fk_donor_blood    FOREIGN KEY (blood_group_id) REFERENCES blood_group(blood_group_id),
  CONSTRAINT fk_donor_hospital FOREIGN KEY (hospital_id)   REFERENCES hospital(hospital_id)
) ENGINE=InnoDB COMMENT='Blood donors registered by hospital staff';

CREATE TABLE resource (
  resource_id        INT          AUTO_INCREMENT PRIMARY KEY,
  hospital_id        INT          NOT NULL,
  resource_name      VARCHAR(150) NOT NULL,
  resource_type      VARCHAR(50)  NOT NULL,    -- ICU Bed, Ventilator, Ambulance …
  total_quantity     INT          NOT NULL,
  available_quantity INT          NOT NULL,
  status             ENUM('AVAILABLE','UNAVAILABLE') NOT NULL DEFAULT 'AVAILABLE',
  CONSTRAINT fk_resource_hospital FOREIGN KEY (hospital_id) REFERENCES hospital(hospital_id),
  CONSTRAINT chk_resource_total   CHECK (total_quantity     >= 0),
  CONSTRAINT chk_resource_avail   CHECK (available_quantity >= 0 AND available_quantity <= total_quantity)
) ENGINE=InnoDB COMMENT='Emergency resources owned by hospitals';
