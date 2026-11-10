USE emergency_system;
CREATE INDEX idx_inv_group_avail ON blood_inventory(blood_group_id, available_units);
CREATE INDEX idx_er_status_prio  ON emergency_request(status, priority, required_by);
CREATE INDEX idx_er_hospital     ON emergency_request(hospital_id);
CREATE INDEX idx_res_request     ON blood_reservation(request_id, status);