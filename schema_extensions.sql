-- Benchmark Schema Extensions for Postgres Air
-- Supports Q6 (Self-join), Q10 (Recursive CTE), Q11 (Optimistic Locking),
-- Q14 (pgvector Cosine Search), and Q15 (Hybrid BM25 + Vector RRF Search).

SET search_path TO postgres_air, public;

-- 1. Employee Table for Self-Joins (Q6) and Recursive Hierarchy (Q10)
CREATE TABLE IF NOT EXISTS employee (
    employee_id SERIAL PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    department TEXT NOT NULL,
    salary NUMERIC(10, 2) NOT NULL,
    manager_id INT REFERENCES employee(employee_id)
);

CREATE INDEX IF NOT EXISTS employee_manager_id ON employee(manager_id);

-- Populate standard hierarchy if empty
INSERT INTO employee (employee_id, first_name, last_name, email, department, salary, manager_id)
VALUES
    (1, 'Eleanor', 'Vance', 'e.vance@postgresair.com', 'Executive', 250000.00, NULL),
    (2, 'Marcus', 'Brody', 'm.brody@postgresair.com', 'Operations', 180000.00, 1),
    (3, 'Sophia', 'Chen', 's.chen@postgresair.com', 'Engineering', 190000.00, 1),
    (4, 'David', 'Kim', 'd.kim@postgresair.com', 'Operations', 120000.00, 2),
    (5, 'Elena', 'Rostova', 'e.rostova@postgresair.com', 'Flight Crew', 110000.00, 2),
    (6, 'Tariq', 'Al-Mansoor', 't.almansoor@postgresair.com', 'Engineering', 140000.00, 3),
    (7, 'Chloe', 'Dubois', 'c.dubois@postgresair.com', 'Engineering', 135000.00, 3),
    (8, 'Liam', 'O''Connor', 'l.oconnor@postgresair.com', 'Flight Crew', 95000.00, 5),
    (9, 'Aaliyah', 'Patel', 'a.patel@postgresair.com', 'Flight Crew', 92000.00, 5),
    (10, 'Lucas', 'Silva', 'l.silva@postgresair.com', 'Engineering', 115000.00, 6)
ON CONFLICT (employee_id) DO NOTHING;

SELECT setval('employee_employee_id_seq', (SELECT COALESCE(MAX(employee_id), 1) FROM employee));

-- 2. Optimistic Locking (Q11)
ALTER TABLE flight ADD COLUMN IF NOT EXISTS version INT NOT NULL DEFAULT 1;
ALTER TABLE account ADD COLUMN IF NOT EXISTS version INT NOT NULL DEFAULT 1;

-- 3. Vector & Full-Text Search Extensions on Airport (Q14, Q15)
ALTER TABLE airport ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE airport ADD COLUMN IF NOT EXISTS embedding vector(384);
ALTER TABLE airport ADD COLUMN IF NOT EXISTS search_tsv tsvector;

-- Populate description & search_tsv for airports
UPDATE airport
SET description = 'Major international airport hub in ' || city || ', ' || COALESCE(iso_country, 'Global') || ' (' || airport_name || ') serving global routes and commercial flights.',
    search_tsv = to_tsvector('english', airport_name || ' ' || city || ' ' || COALESCE(iso_country, ''))
WHERE description IS NULL;

-- Populate deterministic mock 384-dimensional unit embeddings for airports for cosine similarity search
UPDATE airport
SET embedding = (
    SELECT ('[' || string_agg(sin(i * 0.17 + (ascii(substr(airport_code, 1, 1)) * 3 + ascii(substr(airport_code, 2, 1)))::numeric)::text, ',') || ']')::vector(384)
    FROM generate_series(1, 384) i
)
WHERE embedding IS NULL;

-- Full-text GIN index and pgvector HNSW index
CREATE INDEX IF NOT EXISTS airport_search_tsv_idx ON airport USING GIN(search_tsv);
CREATE INDEX IF NOT EXISTS airport_embedding_hnsw_idx ON airport USING hnsw (embedding vector_cosine_ops);


-- 4. High-Concurrency Seat Allocation & Inventory Contention (HQ14)
CREATE TABLE IF NOT EXISTS flight_seat_inventory (
    flight_id INT NOT NULL,
    seat_no TEXT NOT NULL,
    passenger_name TEXT,
    account_id INT,
    reserved_at TIMESTAMPTZ,
    status TEXT NOT NULL DEFAULT 'AVAILABLE',
    version INT NOT NULL DEFAULT 1,
    PRIMARY KEY (flight_id, seat_no)
);

CREATE INDEX IF NOT EXISTS idx_seat_inventory_avail 
ON flight_seat_inventory (flight_id, status) 
WHERE status = 'AVAILABLE';

-- Seed 3 flights (101, 102, 103) with 50 seats each (45 reserved, 5 available)
INSERT INTO flight_seat_inventory (flight_id, seat_no, status, version)
SELECT f.fid, 'SEAT-' || lpad(s.sno::text, 3, '0'), 
       CASE WHEN s.sno <= 45 THEN 'RESERVED' ELSE 'AVAILABLE' END, 
       1
FROM (VALUES (101), (102), (103)) AS f(fid)
CROSS JOIN generate_series(1, 50) AS s(sno)
ON CONFLICT (flight_id, seat_no) DO NOTHING;

-- 5. Staging Table for High-Volume Batch Upsert (HQ12)
CREATE TABLE IF NOT EXISTS flight_status_update (
    flight_id INT PRIMARY KEY,
    status TEXT NOT NULL,
    actual_departure TIMESTAMPTZ,
    actual_arrival TIMESTAMPTZ,
    update_ts TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    version INT NOT NULL DEFAULT 1
);
