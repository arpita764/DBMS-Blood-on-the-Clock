
-- =============================================================
-- FILE: 03b_resource_indexes.sql
-- PURPOSE: Indexes for resource requests and allocations
-- =============================================================

USE emergency_system;

-- Resource request indexes
CREATE INDEX idx_rreq_hospital
    ON resource_request (hospital_id);

CREATE INDEX idx_rreq_status_prio
    ON resource_request (status, priority, required_by);

-- Resource allocation indexes
CREATE INDEX idx_ralloc_req_status
    ON resource_allocation (resource_request_id, status);

CREATE INDEX idx_ralloc_resource_status
    ON resource_allocation (resource_id, status);
