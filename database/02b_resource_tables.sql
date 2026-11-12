-- =============================================================
-- FILE   : 02b_resource_tables.sql
-- PURPOSE: Introduces resource request and allocation tables.
--          Extends the schema to support tracking emergency
--          resource requests (ICU beds, ventilators, ambulances)
--          and the partial allocations that fulfil them.
--
-- DEPENDS ON (must run after):
--   02_hospital_schema.sql  → hospital, app_user, resource
--   02a_tables.sql          → (no dependency from these tables,
--                              but file ordering must be respected)
--
-- DOES NOT MODIFY:
--   02_hospital_schema.sql
--   02a_tables.sql
--   Any other existing file.
--
-- NAMING CONVENTIONS (match existing schema):
--   FK constraints  : fk_<table_abbrev>_<ref_concept>
--   CHECK constraints: chk_<table_abbrev>_<field>
--   Table abbreviations:
--     rreq  = resource_request
--     ralloc = resource_allocation
--     rsc   = resource (the existing resource table)
-- =============================================================
USE emergency_system;

-- =============================================================
-- TABLE 1: resource_request
--
-- Represents a hospital's request for a type of emergency
-- resource (e.g. 'ICU Bed', 'Ventilator', 'Ambulance').
--
-- Key design decisions:
--   • resource_type is VARCHAR(50), not a FK to resource.
--     A request is for a *type* of resource, not a specific
--     supplier's row.  Any hospital's matching resource rows
--     can supply it via resource_allocation.
--   • No resource_id FK here — the supplying hospital is
--     identified only at allocation time (resource_allocation).
--   • status lifecycle:
--       PENDING            → no allocations yet
--       PARTIALLY_FULFILLED→ some units allocated, not all
--       FULFILLED          → quantity_allocated = quantity_required
--       CANCELLED          → request withdrawn
--   • required_by and created_at follow the same pattern as
--     emergency_request (DATETIME, no CHECK on time order
--     at table level — enforced by application/procedure).
-- =============================================================
CREATE TABLE resource_request (
  resource_request_id INT          AUTO_INCREMENT PRIMARY KEY,
  hospital_id         INT          NOT NULL,
  resource_type       VARCHAR(50)  NOT NULL,
  quantity_required   INT          NOT NULL,
  priority            ENUM('CRITICAL','HIGH','MEDIUM','LOW')
                                   NOT NULL DEFAULT 'MEDIUM',
  status              ENUM('PENDING','PARTIALLY_FULFILLED',
                           'FULFILLED','CANCELLED')
                                   NOT NULL DEFAULT 'PENDING',
  created_at          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  required_by         DATETIME     NOT NULL,
  created_by          INT          NULL,

  CONSTRAINT fk_rreq_hospital FOREIGN KEY (hospital_id)
      REFERENCES hospital(hospital_id),

  CONSTRAINT fk_rreq_user    FOREIGN KEY (created_by)
      REFERENCES app_user(user_id),

  CONSTRAINT chk_rreq_qty    CHECK (quantity_required > 0)

) ENGINE=InnoDB
  COMMENT='Emergency resource requests (ICU beds, ventilators, ambulances, etc.)';


-- =============================================================
-- TABLE 2: resource_allocation
--
-- Records each partial allocation made against a resource_request.
-- Multiple rows can exist for the same resource_request_id,
-- enabling incremental fulfilment from one or many hospitals.
--
-- Key design decisions:
--   • resource_id FK points to the specific row in the
--     resource table that is being drawn from.  That row
--     already carries hospital_id, so the supplying hospital
--     is identified implicitly through resource.hospital_id.
--   • status ENUM: ALLOCATED (active) / RELEASED (returned).
--     There is no ACTIVE status per the approved design.
--   • released_by and released_at are NULL until a release
--     occurs — they are populated by the release procedure.
--   • allocated_by is nullable (consistent with reserved_by
--     and created_by in existing tables).
-- =============================================================
CREATE TABLE resource_allocation (
  allocation_id       INT      AUTO_INCREMENT PRIMARY KEY,
  resource_request_id INT      NOT NULL,
  resource_id         INT      NOT NULL,
  quantity_allocated  INT      NOT NULL,
  status              ENUM('ALLOCATED','RELEASED')
                               NOT NULL DEFAULT 'ALLOCATED',
  allocated_by        INT      NULL,
  allocated_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  released_by         INT      NULL,
  released_at         DATETIME NULL,

  CONSTRAINT fk_ralloc_rreq     FOREIGN KEY (resource_request_id)
      REFERENCES resource_request(resource_request_id),

  CONSTRAINT fk_ralloc_resource FOREIGN KEY (resource_id)
      REFERENCES resource(resource_id),

  CONSTRAINT fk_ralloc_alloc_user FOREIGN KEY (allocated_by)
      REFERENCES app_user(user_id),

  CONSTRAINT fk_ralloc_rel_user   FOREIGN KEY (released_by)
      REFERENCES app_user(user_id),

  CONSTRAINT chk_ralloc_qty     CHECK (quantity_allocated > 0)

) ENGINE=InnoDB
  COMMENT='Partial or full resource allocations against a resource_request';
