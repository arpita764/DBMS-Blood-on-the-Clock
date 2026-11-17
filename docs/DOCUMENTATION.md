# Blood on the Clock — Project Documentation

## 1. Problem statement

In emergency medicine, blood and critical resources (ICU beds, ventilators, ambulances) are scarce and distributed across many hospitals. When a hospital faces an emergency, it must rapidly find a supplier with compatible stock, reserve units, and fulfil the request — while keeping inventory consistent across all parties. Beyond the structured logistics, hospitals also keep rich, free-text emergency case narratives whose most useful query is *"have we handled a similar emergency before?"* — a semantic similarity problem.

Existing manual coordination (phone calls, spreadsheets) is slow, error-prone, and gives no visibility across the network. There is no way to search past emergencies by meaning.

## 2. Objectives

- Model the emergency blood & resource coordination domain relationally with strong integrity.
- Implement the full request lifecycle (create → reserve → fulfil/release → cancel) as transactional stored procedures with row-level locking.
- Provide a real-time, cross-hospital view of inventory and requests through a web application.
- Add a vector database for unstructured emergency case files with semantic similarity search.
- Enforce authentication and role-based access control.
- Justify the choice of each database paradigm by the nature of the data.

## 3. Scope

In scope: blood inventory, emergency blood requests and reservations, resource inventory, resource requests and allocations, donor registry, hospital directory, emergency case files with semantic search, admin user management, authentication/authorisation.

Out of scope: live GPS tracking, billing, patient electronic health records, public-facing donor self-registration.

## 4. Functional requirements

- **FR1 Authentication** — users log in with email/password; sessions are JWT-based; passwords are bcrypt-hashed.
- **FR2 Authorisation** — two roles: `ADMIN` (full access incl. user management) and `HOSPITAL_STAFF` (operational access scoped to records).
- **FR3 Blood inventory** — view availability per hospital/blood group (via a SQL view); filter by city/group.
- **FR4 Blood requests** — create emergency requests; reserve compatible blood from a supplier hospital; fulfil reservations (convert reserved→allocated); release reservations (restore stock); cancel requests.
- **FR5 Resource inventory/requests** — manage ICU beds, ventilators, ambulances; create requests; allocate across supplier hospitals with partial fulfilment; cancel and restore.
- **FR6 Donor registry** — list/filter donors; register new donors.
- **FR7 Hospital directory** — list hospitals; full-text search across name/city/type.
- **FR8 Emergency cases (vector DB)** — create case files (narrative, timeline, tags, linked requests); semantic similarity search ("find similar emergencies"); view case detail with timeline; change status; add timeline events.
- **FR9 Admin** — create/disable users; passwords hashed with bcrypt.
- **FR10 Dashboard** — aggregated counts, low-stock alerts, pending requests by priority.

## 5. ER diagram & relational schema

- ER diagram: `er_diagram_chen.png` (Chen notation) at the repository root.
- Relational schema: `relational_schema.png` at the repository root.

**Entities:** hospital, app_user, donor, blood_group, blood_compatibility, blood_inventory, emergency_request, blood_reservation, inventory_audit, resource, resource_request, resource_allocation.

**Key relationships:**
- `app_user` N:1 `hospital` (staff belong to a hospital; admins do not)
- `donor` N:1 `hospital`, N:1 `blood_group`
- `blood_inventory` 1:1 (per hospital + blood group), N:1 `hospital`, N:1 `blood_group`
- `emergency_request` N:1 `hospital`, N:1 `blood_group`, N:1 `app_user` (created_by)
- `blood_reservation` N:1 `emergency_request`, N:1 `hospital`, N:1 `blood_group`
- `blood_compatibility` M:N self-reference on `blood_group` (donor → recipient)
- `resource` N:1 `hospital`; `resource_request` N:1 `hospital`; `resource_allocation` N:1 `resource_request`, N:1 `resource`
- Vector DB `emergency_cases` documents reference SQL `hospital` ids and `emergency_request`/`resource_request` ids.

## 6. Database choice and justification

| Data | Database | Why |
|---|---|---|
| Hospitals, users, inventory, requests, reservations, resources, allocations | MySQL (relational) | Strong relations, foreign keys, status state machines, transactional multi-row updates with locking, aggregate reporting, full-text search on structured fields. |
| Emergency case narratives + timelines | LanceDB (vector) | Unstructured, evolving, text-heavy documents; the key query is semantic similarity ("similar emergencies") over text — keyword/SQL matching misses synonyms. Vector embeddings + cosine similarity solve this. LanceDB is embedded (no server), storing vectors in Lance columnar format on disk. |

Per the syllabus (Unit 4): "Vector databases, Vector search with Relational and NoSQL databases." This project demonstrates exactly that — a relational DB for operational state and a vector DB for semantic search, integrated in one web application.

## 7. Data dictionary / schema description (SQL)

| Table | Purpose | Key columns / constraints |
|---|---|---|
| `hospital` | Registered hospitals/blood banks | PK hospital_id; UNIQUE group lookups; status ENUM(ACTIVE,INACTIVE) |
| `app_user` | System users | PK user_id; UNIQUE email; role ENUM(ADMIN,HOSPITAL_STAFF); CHECK: staff must have hospital_id |
| `donor` | Blood donors | PK donor_id; FK blood_group, hospital; availability ENUM |
| `blood_group` | ABO/Rh lookup | PK blood_group_id; UNIQUE group_name |
| `blood_compatibility` | M:N donor→recipient | composite PK (donor_group_id, recipient_group_id); FKs to blood_group |
| `blood_inventory` | Stock per hospital/group | PK inventory_id; UNIQUE(hospital_id,blood_group_id); CHECK available/reserved/allocated ≥ 0 |
| `emergency_request` | Blood requests | PK request_id; ENUM priority; ENUM status(PENDING,RESERVED,FULFILLED,CANCELLED); CHECK quantity_required>0; CHECK required_by>created_at |
| `blood_reservation` | Reserved units | PK reservation_id; FKs to request/hospital/blood_group; CHECK units_reserved>0; ENUM status(RESERVED,ALLOCATED,CANCELLED) |
| `inventory_audit` | Trigger audit log | filled by `trg_inventory_audit` |
| `resource` | Emergency resources | PK resource_id; FK hospital; CHECK available between 0 and total |
| `resource_request` | Resource requests | PK; ENUM priority; ENUM status(PENDING,PARTIALLY_FULFILLED,FULFILLED,CANCELLED) |
| `resource_allocation` | Allocations | PK; FKs to resource_request, resource, users; ENUM status(ALLOCATED,RELEASED) |

**Vector DB collection** (`emergency_cases` in LanceDB): each document has scalar metadata (caseId, title, narrative, caseType, severity, status, bloodGroup, resourceType, patientAgeGroup, createdBy/Name, timestamps) plus JSON-serialised arrays (hospitalIds, hospitalNames, tags, linkedRequestIds, timeline) and a 384-dim `vector` embedding of (title + narrative + type + severity + tags).

## 8. SQL implementation

- **DDL** — `CREATE` across `01–02b`; `ALTER TABLE` in `10_alter_table_examples.sql` (add columns, add indexes, modify column, add CHECK constraint, add FULLTEXT index); `DROP` of procedures/functions/triggers/temp tables. Satisfies the CREATE/ALTER/DROP requirement.
- **Constraints** — primary keys, foreign keys, UNIQUE, ENUM, CHECK (quantities ≥ 0, time ordering, staff-must-have-hospital, fulfilled quantity).
- **Indexes** — `03`, `03a`, `03b` (composite indexes on hot query paths) plus an ALTER-added covering index.
- **Views** — `available_blood_by_hospital` (`04_view.sql`) powering the inventory dashboard.
- **Stored procedures/functions** — `find_available_resources` (proc), `calculate_emergency_priority` (function) in `05`; transactional procedures in `07`: `reserve_blood`, `fulfill_reservation`, `release_reservation`, `allocate_resource_for_request`, `cancel_request`, `cancel_resource_request` — each with `START TRANSACTION`, `FOR UPDATE` row locking, `SIGNAL` on violation, and rollback on error.
- **Triggers** — `trg_inventory_audit` (`08`) writes an audit row when blood inventory available/reserved units change.
- **Transactions/concurrency** — `SELECT … FOR UPDATE` pessimistic locking, consistent lock ordering (parent before child, inventory before change), rollback-on-error handlers.
- **Advanced SQL** (`09` + `11`): JOIN, GROUP BY, HAVING, ORDER BY, aggregates, correlated subqueries, CTE (`WITH`), window functions (`ROW_NUMBER`, `RANK`, `SUM OVER`), set operations (`UNION`/`INTERSECT`/`EXCEPT`), full-text search (`MATCH … AGAINST`).
- **DML** — INSERT (seed + app create), UPDATE (procedures + backfills), DELETE (`09` example), SELECT (everywhere).

## 9. Important queries

See `database/09_.sql` and `database/11_advanced_sql_coverage.sql`. Highlights:

- Pending emergencies ranked by computed priority (uses the stored function).
- Requests per blood group (`GROUP BY` + `COUNT`).
- Hospitals with stock above a threshold (`SUM` + `HAVING`).
- Requests that cannot currently be fulfilled (correlated subquery with compatibility join).
- CTE: blood groups whose requested quantity exceeds the average.
- Window functions: rank requests by quantity within each priority.
- Set operations: hospitals with blood and/or/not resources.
- Full-text search: hospitals matching free-text terms, relevance-ranked.

## 10. Vector database implementation

- **What data becomes embeddings:** the free-text emergency case narrative combined with title, case type, severity and tags.
- **Embedding model:** `Xenova/all-MiniLM-L6-v2`, a 384-dimensional sentence embedding model run locally via Transformers.js (ONNX runtime, in-process). No API key; the model is downloaded once (~25 MB) and cached.
- **How vectors are stored:** LanceDB stores each case document plus a 384-dim `vector` column in the `emergency_cases` table, persisted in the Lance columnar format under `./data/vectordb`. LanceDB runs embedded in the Node.js process (no separate server/Docker).
- **Similarity metric:** cosine similarity. Embeddings are L2-normalised (pooling: mean, normalize: true), so cosine similarity equals the dot product of two normalised vectors. The search embeds the query with the same model and uses LanceDB's `vectorSearch` to retrieve the nearest cases; the score reported is the dot-product cosine.
- **How relevant results are retrieved:** `table.vectorSearch(queryVector).limit(k)` performs an (approximate) nearest-neighbour scan; results are returned ranked by similarity and shown in the UI with a match percentage.

## 11. System architecture

```
Browser (Next.js pages, client components)
        │  fetch (JSON) + HttpOnly JWT cookie
        ▼
Next.js Route Handlers (API layer)  ── src/app/api/*
        │                              │
        ▼                              ▼
   MySQL (mysql2 pool)         LanceDB (embedded) + Transformers.js
   - structured state          - emergency_cases (vectors)
   - procedures/triggers       - semantic search
        │
        ▼
   Edge Middleware (src/middleware.ts)
   - auth check + role-based access control (jose JWT verify)
```

- Pages are client components that call REST endpoints; the API layer is the single integration point with both databases.
- Database credentials come from `.env.local`; secrets never hard-coded.
- Middleware enforces auth on all routes and admin-only on `/api/admin/*` and `/admin/*`.

## 12. Authentication & authorisation

- Two roles: `ADMIN` and `HOSPITAL_STAFF` (minimum 2 satisfied).
- Login validates the bcrypt hash in `app_user`; on success a signed JWT (HS256, 7-day expiry) is set in an `HttpOnly` cookie.
- `requireUser` / `requireAdmin` guards on the server; middleware enforces the same on the edge for both pages and API routes.
- The schema CHECK constraint `chk_user_role` enforces that hospital staff are always tied to a hospital.

## 13. Data validation & integrity

- **Database level:** PK/FK, UNIQUE, ENUM (status/priority/role), CHECK constraints (non-negative quantities, quantity>0, required_by>created_at, staff-must-have-hospital, fulfilled-qty).
- **Trigger level:** `trg_inventory_audit` records every inventory change.
- **Transaction level:** procedures validate status transitions and quantities under locks and reject illegal operations with `SIGNAL`.
- **Application level:** route handlers validate and type-check input before reaching the DB; case ids are regex-validated before use in vector filters.

## 14. Security

- Passwords hashed with bcrypt (cost 12); never stored or logged in plain text.
- DB credentials and JWT secret are environment variables (`.env.local`).
- `HttpOnly` session cookies; CSRF-protected via SameSite=Lax.
- Role-based access control enforced at the edge and in each handler.
- Parameterised queries throughout (no string-interpolated SQL from user input).

## 15. Application screenshots

> Add screenshots of: login, dashboard, blood inventory, blood requests with reservation lifecycle, resource requests with allocation, donors, hospitals full-text search, emergency cases semantic search, case detail with timeline, admin user management. *(Captured during the demo.)*

## 16. Testing results

> Test cases to document/run:
> - **Auth:** valid login succeeds; invalid password rejected (401); disabled account rejected.
> - **Blood reserve:** reserving compatible blood decrements `available_units` and increments `reserved_units`; reserving more than available is rejected; reserving for a non-PENDING request is rejected.
> - **Fulfil:** moves reserved→allocated and sets request status to FULFILLED when fully covered.
> - **Release/cancel:** restores stock; preserves ALLOCATED history.
> - **Concurrency:** two concurrent reservations for the last units — one succeeds, one is rejected (FOR UPDATE locking).
> - **Trigger:** an inventory update inserts a row into `inventory_audit`.
> - **Vector search:** a query like "road accident needing O-" returns the mass-casualty case ranked highest; a "dengue" query returns the outbreak case.
> - **Full-text:** "blood trauma" returns relevant hospitals ranked by relevance.
> - **Roles:** a staff token cannot access `/api/admin/users` (403).
> *(Record actual results/outputs here during testing.)*

## 17. Conclusion & future enhancements

The project demonstrates a clear connection between database concepts (design, constraints, transactions, triggers, procedures, views, indexes, advanced SQL) and a functional web application, going well beyond CRUD. It justifies the use of a relational database for structured operational state and a vector database for unstructured case narratives and semantic search.

**Future enhancements:** geolocation-based nearest-hospital matching (the `latitude`/`longitude` columns are already added via ALTER); a real-time pub/sub alert layer; donor self-service portal; per-hospital analytics dashboards; replacing flat-file LanceDB with a managed vector service at scale; automated test suite.

## 18. Mapping to the DBMS syllabus

| Syllabus unit | Where covered |
|---|---|
| Unit 1 — DB design, ER, relational schema, SQL DDL, constraints/keys | ER + relational schema images; `01–02b` DDL; PK/FK/UNIQUE/ENUM/CHECK |
| Unit 2 — Advanced SQL (modifications, aggregates, subqueries, joins, views, triggers, procedures, CTE, window functions, full-text) | `05`, `07`, `08`, `04_view`, `09`, `11` |
| Unit 3 — Query optimization, functional dependencies, normal forms (1NF/2NF/3NF/BCNF) | Normalised schema (each non-key attribute depends on the whole key); indexes; documented query optimisation |
| Unit 4 — Transactions, concurrency, locking, NoSQL/Vector databases, vector search, Next.js + SQL | `07` (transactions + `FOR UPDATE`); LanceDB vector DB; Transformers.js embeddings + cosine search; Next.js web app + SQL |
