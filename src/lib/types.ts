// Shared TypeScript types for SQL entities and the vector-DB case documents.

export type Role = "ADMIN" | "HOSPITAL_STAFF";
export type Priority = "CRITICAL" | "HIGH" | "MEDIUM" | "LOW";

export interface AppUser {
  user_id: number;
  full_name: string;
  email: string;
  role: Role;
  account_status: "ACTIVE" | "DISABLED";
  hospital_id: number | null;
  hospital_name?: string;
}

export interface Hospital {
  hospital_id: number;
  hospital_name: string;
  address: string | null;
  city: string;
  phone: string | null;
  hospital_type: string | null;
  status: "ACTIVE" | "INACTIVE";
  contact_email?: string | null;
}

export interface BloodGroup {
  blood_group_id: number;
  group_name: string;
}

export interface BloodInventory {
  inventory_id: number;
  hospital_id: number;
  blood_group_id: number;
  group_name?: string;
  hospital_name?: string;
  city?: string;
  available_units: number;
  reserved_units: number;
  allocated_units: number;
  last_updated: string;
}

export type RequestStatus = "PENDING" | "RESERVED" | "FULFILLED" | "CANCELLED";

export interface EmergencyRequest {
  request_id: number;
  hospital_id: number;
  blood_group_id: number;
  group_name?: string;
  hospital_name?: string;
  city?: string;
  quantity_required: number;
  priority: Priority;
  status: RequestStatus;
  created_at: string;
  required_by: string;
  created_by: number | null;
  created_by_name?: string;
  priority_score?: number | null;
}

export type ReservationStatus = "RESERVED" | "ALLOCATED" | "CANCELLED";

export interface BloodReservation {
  reservation_id: number;
  request_id: number;
  hospital_id: number;
  blood_group_id: number;
  group_name?: string;
  hospital_name?: string;
  units_reserved: number;
  status: ReservationStatus;
  reserved_by: number | null;
  reserved_by_name?: string;
  reserved_at: string;
}

export interface Donor {
  donor_id: number;
  donor_name: string;
  phone: string;
  city: string;
  blood_group_id: number;
  group_name?: string;
  hospital_id: number;
  hospital_name?: string;
  availability_status: "AVAILABLE" | "UNAVAILABLE";
  last_donation_date: string | null;
  eligibility_notes?: string | null;
}

export interface Resource {
  resource_id: number;
  hospital_id: number;
  hospital_name?: string;
  city?: string;
  resource_name: string;
  resource_type: string;
  total_quantity: number;
  available_quantity: number;
  status: "AVAILABLE" | "UNAVAILABLE";
}

export type ResourceRequestStatus =
  | "PENDING"
  | "PARTIALLY_FULFILLED"
  | "FULFILLED"
  | "CANCELLED";

export interface ResourceRequest {
  resource_request_id: number;
  hospital_id: number;
  hospital_name?: string;
  city?: string;
  resource_type: string;
  quantity_required: number;
  priority: Priority;
  status: ResourceRequestStatus;
  created_at: string;
  required_by: string;
  created_by: number | null;
  created_by_name?: string;
}

export type AllocationStatus = "ALLOCATED" | "RELEASED";

export interface ResourceAllocation {
  allocation_id: number;
  resource_request_id: number;
  resource_id: number;
  resource_name?: string;
  supplier_hospital_name?: string;
  quantity_allocated: number;
  status: AllocationStatus;
  allocated_by: number | null;
  allocated_by_name?: string;
  allocated_at: string;
  released_by: number | null;
  released_at: string | null;
}

export interface DashboardStats {
  hospitalsActive: number;
  bloodRequestsOpen: number;
  resourceRequestsOpen: number;
  totalAvailableUnits: number;
  casesOpen: number;
  lowStock: BloodInventory[];
  pendingByPriority: { priority: Priority; count: number }[];
}

// ---- Vector database (LanceDB) ----
export interface CaseTimelineEvent {
  at: string;
  actor: string;
  event: string;
  note?: string;
}

export type CaseType = "BLOOD" | "RESOURCE" | "MULTI";
export type CaseStatus = "OPEN" | "RESOLVED" | "CANCELLED";

export interface EmergencyCase {
  caseId: string;
  title: string;
  narrative: string;
  caseType: CaseType;
  severity: Priority;
  priorityLabel: string;
  bloodGroup: string | null;
  resourceType: string | null;
  patientAgeGroup: string;
  status: CaseStatus;
  createdBy: number;
  createdByName: string;
  createdAt: string;
  updatedAt: string;
  hospitalIds: number[];
  hospitalNames: string[];
  tags: string[];
  linkedRequestIds: number[];
  timeline: CaseTimelineEvent[];
}
