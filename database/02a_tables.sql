USE emergency_system;

CREATE TABLE blood_inventory (
  inventory_id    INT AUTO_INCREMENT PRIMARY KEY,
  hospital_id     INT NOT NULL,
  blood_group_id  INT NOT NULL,
  available_units INT NOT NULL DEFAULT 0,
  reserved_units  INT NOT NULL DEFAULT 0,
  allocated_units INT NOT NULL DEFAULT 0,
  last_updated    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
                  ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_inv_hospital FOREIGN KEY (hospital_id)    REFERENCES hospital(hospital_id),
  CONSTRAINT fk_inv_blood    FOREIGN KEY (blood_group_id) REFERENCES blood_group(blood_group_id),
  CONSTRAINT uq_inv_hosp_grp UNIQUE (hospital_id, blood_group_id),
  CONSTRAINT chk_inv_avail   CHECK (available_units >= 0),
  CONSTRAINT chk_inv_resv    CHECK (reserved_units  >= 0),
  CONSTRAINT chk_inv_alloc   CHECK (allocated_units >= 0)
) ENGINE=InnoDB COMMENT='Blood stock per hospital and blood group';

CREATE TABLE emergency_request (
  request_id        INT AUTO_INCREMENT PRIMARY KEY,
  hospital_id       INT NOT NULL,                 -- hospital that needs blood
  blood_group_id    INT NOT NULL,
  quantity_required INT NOT NULL,
  priority          ENUM('CRITICAL','HIGH','MEDIUM','LOW') NOT NULL DEFAULT 'MEDIUM',
  status            ENUM('PENDING','RESERVED','FULFILLED','CANCELLED') NOT NULL DEFAULT 'PENDING',
  created_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  required_by       DATETIME NOT NULL,
  created_by        INT NULL,
  CONSTRAINT fk_er_hospital FOREIGN KEY (hospital_id)    REFERENCES hospital(hospital_id),
  CONSTRAINT fk_er_blood    FOREIGN KEY (blood_group_id) REFERENCES blood_group(blood_group_id),
  CONSTRAINT fk_er_user     FOREIGN KEY (created_by)     REFERENCES app_user(user_id),
  CONSTRAINT chk_er_qty     CHECK (quantity_required > 0),
  CONSTRAINT chk_er_time    CHECK (required_by > created_at)
) ENGINE=InnoDB COMMENT='Emergency blood requests';

CREATE TABLE blood_reservation (
  reservation_id INT AUTO_INCREMENT PRIMARY KEY,
  request_id     INT NOT NULL,
  hospital_id    INT NOT NULL,                    -- hospital supplying the blood
  blood_group_id INT NOT NULL,                    -- group actually reserved
  units_reserved INT NOT NULL,
  status         ENUM('RESERVED','ALLOCATED','CANCELLED') NOT NULL DEFAULT 'RESERVED',
  reserved_by    INT NULL,
  reserved_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_res_request  FOREIGN KEY (request_id)     REFERENCES emergency_request(request_id),
  CONSTRAINT fk_res_hospital FOREIGN KEY (hospital_id)    REFERENCES hospital(hospital_id),
  CONSTRAINT fk_res_blood    FOREIGN KEY (blood_group_id) REFERENCES blood_group(blood_group_id),
  CONSTRAINT fk_res_user     FOREIGN KEY (reserved_by)    REFERENCES app_user(user_id),
  CONSTRAINT chk_res_units   CHECK (units_reserved > 0)
) ENGINE=InnoDB COMMENT='Blood units reserved for a request';

CREATE TABLE inventory_audit (
  audit_id      INT AUTO_INCREMENT PRIMARY KEY,
  inventory_id  INT NOT NULL,
  old_available INT NOT NULL,
  new_available INT NOT NULL,
  old_reserved  INT NOT NULL,
  new_reserved  INT NOT NULL,
  changed_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_audit_inv FOREIGN KEY (inventory_id) REFERENCES blood_inventory(inventory_id)
) ENGINE=InnoDB COMMENT='Filled automatically by trigger';