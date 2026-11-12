-- =============================================================
-- FILE   : 11_advanced_sql_coverage.sql
-- PURPOSE: Demonstrate the remaining Unit 2 (Advanced SQL) features
--          that are not shown elsewhere:
--            A. Full-text search (MATCH ... AGAINST)
--            B. CTE (WITH ... )
--            C. Window functions (ROW_NUMBER, RANK, SUM OVER)
--            D. Set operations (UNION / INTERSECT / EXCEPT)
--
-- REQUIRES: MySQL 8.0.31+ for INTERSECT / EXCEPT (seed uses 8.0.33).
--           InnoDB FULLTEXT is supported since MySQL 5.6.
-- RUN     : After 10_alter_table_examples.sql (adds the FULLTEXT index).
-- =============================================================
USE emergency_system;

-- =============================================================
-- A. FULL-TEXT SEARCH
--    Add a FULLTEXT index on hospital descriptive columns, then run a
--    natural-language relevance-ranked search.
-- =============================================================
ALTER TABLE hospital
  ADD FULLTEXT INDEX ft_hospital_search (hospital_name, city, hospital_type);

-- Hospitals matching "blood trauma" ranked by relevance
SELECT hospital_id,
       hospital_name,
       city,
       hospital_type,
       MATCH(hospital_name, city, hospital_type)
         AGAINST('blood trauma' IN NATURAL LANGUAGE MODE) AS relevance
FROM hospital
WHERE MATCH(hospital_name, city, hospital_type)
        AGAINST('blood trauma' IN NATURAL LANGUAGE MODE)
ORDER BY relevance DESC;


-- =============================================================
-- B. CTE (Common Table Expression, WITH ...)
--    Blood groups whose total requested quantity exceeds the average.
-- =============================================================
WITH group_totals AS (
    SELECT bg.group_name,
           SUM(er.quantity_required) AS total_req
    FROM emergency_request er
    JOIN blood_group bg ON bg.blood_group_id = er.blood_group_id
    GROUP BY bg.group_name
),
avg_total AS (
    SELECT AVG(total_req) AS avg_req
    FROM group_totals
)
SELECT g.group_name,
       g.total_req,
       ROUND(a.avg_req, 2) AS group_average
FROM group_totals g
CROSS JOIN avg_total a
WHERE g.total_req > a.avg_req
ORDER BY g.total_req DESC;


-- =============================================================
-- C. WINDOW FUNCTIONS
--    Rank non-cancelled blood requests by quantity within each priority,
--    and show the running total per priority.
-- =============================================================
SELECT request_id,
       hospital_id,
       priority,
       quantity_required,
       ROW_NUMBER() OVER (PARTITION BY priority
                          ORDER BY quantity_required DESC) AS qty_row_num,
       RANK()       OVER (PARTITION BY priority
                          ORDER BY quantity_required DESC) AS qty_rank,
       SUM(quantity_required) OVER (PARTITION BY priority) AS priority_total
FROM emergency_request
WHERE status <> 'CANCELLED'
ORDER BY FIELD(priority,'CRITICAL','HIGH','MEDIUM','LOW'), qty_row_num;


-- =============================================================
-- D. SET OPERATIONS
--    Helper views + UNION / INTERSECT / EXCEPT over them.
-- =============================================================
CREATE OR REPLACE VIEW v_hospitals_with_blood AS
    SELECT DISTINCT hospital_id FROM blood_inventory;

CREATE OR REPLACE VIEW v_hospitals_with_resources AS
    SELECT DISTINCT hospital_id FROM resource;

-- UNION: hospitals that have blood inventory OR resources
SELECT hospital_id FROM v_hospitals_with_blood
UNION
SELECT hospital_id FROM v_hospitals_with_resources;

-- INTERSECT: hospitals that have BOTH blood inventory AND resources
SELECT hospital_id FROM v_hospitals_with_blood
INTERSECT
SELECT hospital_id FROM v_hospitals_with_resources;

-- EXCEPT: hospitals that have blood inventory but NO resources
SELECT hospital_id FROM v_hospitals_with_blood
EXCEPT
SELECT hospital_id FROM v_hospitals_with_resources;
