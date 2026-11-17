# Blood on the Clock

An emergency blood & critical-resource coordination system for a network of hospitals. It manages blood inventory, emergency blood requests with reservation/fulfilment/release lifecycle, ICU beds / ventilators / ambulances, a donor registry, and **emergency case files** with **semantic similarity search**.

Built for the DBMS Level 3 Project. It uses **two database paradigms**: a relational database (MySQL) for the structured operational data, and an **embedded vector database (LanceDB)** for unstructured case narratives with vector similarity search.

---

## Tech stack

| Layer | Technology |
|---|---|
| Frontend + API | Next.js 14 (App Router) + React + TypeScript + Tailwind CSS |
| SQL database | MySQL 8 (relational schema, constraints, transactions, triggers, procedures, views, indexes, full-text search) |
| Vector database | LanceDB (embedded, runs in-process in Node.js — no server) |
| Embeddings | `Xenova/all-MiniLM-L6-v2` via Transformers.js (384-dim, runs locally, no API key) |
| Auth | JWT sessions (jose) + bcrypt password hashing |
| DB driver | mysql2 |

### Why two databases (justification)

- **MySQL** holds the structured, integrity-critical operational state: hospitals, users, blood inventory, requests, reservations, resources, allocations. These have strong relations, foreign keys, status state machines and transactional requirements (e.g. reserving blood must atomically debit available stock and credit reserved stock). A relational DB is the correct fit.
- **LanceDB** holds emergency *case files*: rich, free-text incident narratives, timelines and tags. These are unstructured, evolve over time, and the key operation is *"find similar past emergencies"* — semantic similarity search over text. Relational SQL handles this poorly (keyword LIKE matching misses synonyms); a vector database with embeddings is the correct fit. LanceDB is embedded (no Docker/server), storing vectors in the Lance columnar format on local disk.

---

## Prerequisites

- Node.js 20+ (developed on Node 24)
- MySQL 8.0.31+ (for `INTERSECT`/`EXCEPT` and InnoDB `FULLTEXT`)
- npm

## Setup

### 1. Database (MySQL)

Create the schema, tables, indexes, views, procedures, triggers and seed data by running the SQL files **in order**:

```
mysql -u root -p < database/00_create_database.sql
mysql -u root -p emergency_system < database/01_lookup_tables.sql
mysql -u root -p emergency_system < database/02_hospital_schema.sql
mysql -u root -p emergency_system < database/02a_tables.sql
mysql -u root -p emergency_system < database/02b_resource_tables.sql
mysql -u root -p emergency_system < database/03_indexes.sql
mysql -u root -p emergency_system < database/03a_indexes.sql
mysql -u root -p emergency_system < database/03b_resource_indexes.sql
mysql -u root -p emergency_system < database/04_view.sql
mysql -u root -p emergency_system < database/05_stored_procedure_and_function.sql
mysql -u root -p emergency_system < database/06_seed_data.sql
mysql -u root -p emergency_system < database/07_transactions.sql
mysql -u root -p emergency_system < database/08_trigger.sql
mysql -u root -p emergency_system < database/09_.sql        # example queries
mysql -u root -p emergency_system < database/10_alter_table_examples.sql
mysql -u root -p emergency_system < database/11_advanced_sql_coverage.sql
```

Or import all of them in one go from the MySQL Workbench / CLI in this order.

### 2. Configure environment

Copy `.env.example` to `.env.local` and fill in your MySQL credentials:

```
cp .env.example .env.local
```

`.env.local` (never committed) holds `MYSQL_*`, `VECTORDV_PATH` and `JWT_SECRET`.

### 3. Install dependencies

```
npm install
```

### 4. Seed the vector database

```
npm run seed:vectors
```

This creates the LanceDB table at `./data/vectordb` and inserts sample emergency cases. On the first run it downloads the `all-MiniLM-L6-v2` model (~25 MB) into `./data/.models`; it is then cached and works offline.

### 5. Run the app

```
npm run dev
```

Open <http://localhost:3000>. You will be redirected to the login page.

## Demo accounts

All seeded users use the password **`Password@123`** (bcrypt-hashed in the DB).

| Role | Email |
|---|---|
| Admin | `admin@bloodclock.com` |
| Hospital Staff | `priya@citygeneral.com` |
| Hospital Staff | `rajan@apollobb.com` |
| Hospital Staff | `anjali@metrotrauma.com` |
| Hospital Staff | `suresh@sunrisemc.com` |

## Using the app

- **Dashboard** — counts, low-stock alerts, pending requests by priority.
- **Blood Inventory** — availability per hospital/group (backed by a SQL VIEW) with filters.
- **Blood Requests** — create emergency blood requests, reserve compatible blood from a supplier hospital, fulfil or release reservations, cancel requests (all via transactional stored procedures).
- **Resource Inventory / Requests** — ICU beds, ventilators, ambulances; create requests and allocate across supplier hospitals.
- **Donors** — registry with filtering; register new donors.
- **Hospitals** — directory with **full-text search** (`MATCH ... AGAINST`).
- **Emergency Cases** *(vector DB)* — create rich case files and run **semantic search** ("find similar emergencies").
- **User Management** *(Admin only)* — create users, enable/disable accounts (bcrypt-hashed passwords).

---

## Project structure

```
database/                SQL: schema, indexes, views, procedures, triggers, seed, queries, ALTER, advanced SQL
src/
  app/
    api/                 REST route handlers (the API layer between UI and both databases)
      auth/ blood/ resources/ donors/ hospitals/ cases/ admin/ dashboard/
    blood/ resources/ donors/ hospitals/ cases/ admin/  page UI
    login/  page.tsx
    page.tsx             dashboard
    layout.tsx globals.css
  components/            Shell (nav), ui.tsx (reusable components)
  lib/
    db.ts               MySQL pool + query helpers
    vector.ts           LanceDB + embeddings (vector database layer)
    procedures.ts       helpers to call stored procedures with OUT params
    auth.ts session.ts   JWT auth + bcrypt
    http.ts             API error handling
    api-client.ts       client fetch helper
    format.ts           formatting helpers
    types.ts            shared types
  middleware.ts          route protection + role-based access control
scripts/seed-vectors.mjs vector DB seed
docs/DOCUMENTATION.md    full project documentation
```

## Advanced database concepts demonstrated

SQL (more than the required four): transactions, views, stored procedures/functions, triggers, indexing, full-text search, CTE, window functions, set operations.
Vector: embeddings, vector storage, cosine similarity search, aggregation (caseStats).

## Security notes

- DB credentials and JWT secret are read from environment variables — never hard-coded.
- Passwords are stored only as bcrypt hashes (cost 12); never in plain text.
- Session JWTs are stored in `HttpOnly` cookies.
- Middleware enforces authentication on all routes and role-based access control (Admin-only routes).
- Input is validated at the API layer; database-level CHECK/UNIQUE/ENUM/FK constraints enforce integrity.

## Notes

- The first semantic search or case creation downloads the embedding model (~25 MB) and caches it locally; subsequent runs are offline.
- LanceDB stores data on disk under `./data/vectordb` and the model under `./data/.models` (both git-ignored).
