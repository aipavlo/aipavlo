--- STATISTICS ---
SELECT AUDIT('public.table_name', 'table', 0, 100);
SELECT ANALYZE_STATISTICS('public.table_name');
SELECT GET_COMPLIANCE_STATUS(); -- check vertica actual audit status 
SELECT AUDIT_LICENSE_SIZE(); -- trigger an immediate audit
SELECT /*+DEPOT_FETCH(NONE)*/ (SUM(AUDIT_LENGTH(column_name)) )FROM schema_name.table_name;
SELECT APPROXIMATE_COUNT_DISTINCT(column_name) FROM schema_name.table_name;
-- RESOURCE POOL
SELECT pool_name, node_name, max_query_memory_size_kb, max_memory_size_kb, memory_size_actual_kb FROM V_MONITOR.RESOURCE_POOL_STATUS WHERE pool_name='general';
SELECT name, memorysize, maxmemorysize FROM V_CATALOG.RESOURCE_POOLS;

-- 100 BIGGEST TABLES IN VERTICA DB ACCORDING TO THE TOTAL DISK SPACE
SELECT anchor_table_schema, anchor_table_name, SUM(used_bytes) AS total_used_bytes
FROM v_monitor.column_storage
GROUP BY anchor_table_name, anchor_table_schema
ORDER BY total_used_bytes DESC
LIMIT 100;

-- 100 BIGGEST ROS-CONTAINERS IN VERTICA DB ACCORDING TO THE TOTAL DISK SPACE AND ROWS COUNT
SELECT *
FROM v_monitor.storage_containers
ORDER BY used_bytes DESC, total_row_count DESC
LIMIT 100;

-- CHECK ACTIVE SESSIONS
SELECT * FROM v_monitor.query_requests WHERE user_name = 'dbadmin' AND is_executing = 'True';

-- DROP ALL OTHERS SESSIONS
SELECT CLOSE_ALL_SESSIONS(); -- close all sessions except during session

SELECT EXPORT_OBJECTS( '', 'schema_name.table_name') ; -- export DDL

-- CHECK ALL PROJECTIONS
SELECT * FROM v_catalog.projections WHERE projection_schema = 'schema_name' AND anchor_table_name = 'table_name';
-- CHECK ALL ROS CONTAINERS
SELECT * FROM storage_containers
WHERE SCHEMA_name = 'schema_name' and projection_name like 'table_name%';
-- SELECT EXECTLY 1 CONTAINER (CHOOSE FROM PREVIOUS RESULT)
SELECT * FROM table_name.schema_name 
WHERE lead_storage_oid() = '45035996283468437';


--- DDL ---
-- CHECK ENABLED AND DISABLED CONSTRAINTS
SELECT CONSTRAINT_NAME, CONSTRAINT_TYPE, IS_ENABLED FROM V_CATALOG.TABLE_CONSTRAINTS
WHERE TABLE_NAME = 'table_name' AND CONSTRAINT_SCHEMA_ID = (SELECT SCHEMA_ID FROM V_CATALOG.SCHEMATA WHERE SCHEMA_NAME = 'schema_name');
-- ADD CONSTRAINT
ALTER TABLE schema_name.table_name ADD CONSTRAINT constraint_name PRIMARY KEY (column_name1, column_name2, ...) ENABLED;
-- ENABLE/DISABLE CONSTRAINT
ALTER TABLE schema_name.table_name ALTER CONSTRAINT table_name_PK ENABLED; -- DISABLED
-- SEQUENCE
DROP SEQUENCE IF EXISTS schema_name.sequence_name;
CREATE SEQUENCE IF NOT EXISTS schema_name.sequence_name;
ALTER SEQUENCE schema_name.sequence_name CACHE 1;
-- FLATTEN TABLE REBUILD WITH PARTITION
SELECT REFRESH_COLUMNS ('schema_name.table_name', 'column_name1', 'REBUILD',
TO_CHAR(ADD_MONTHS(current_date, -2),'YYYYMM'),
TO_CHAR(ADD_MONTHS(current_date, -2),'YYYYMM'));


--- FLEX TABLE ---
--DROP TABLE IF EXISTS flex.dwh_flex;
CREATE FLEX TABLE IF NOT EXISTS flex.dwh_flex();
COPY flex.dwh_flex FROM '/file_to_import/dwh.csv.gz' GZIP PARSER fcsvparser();
SELECT maplookup(__raw__, 'request_id') AS request_id FROM flex.dwh_flex;
SELECT COMPUTE_FLEXTABLE_KEYS_AND_BUILD_VIEW('flex.dwh_flex');
--DROP TABLE IF EXISTS src.dwh_table;
CREATE TABLE IF NOT EXISTS src.dwh_table AS SELECT * FROM flex.dwh_flex_view;


--- VSQL ---
-- stop on error
\set ON_ERROR_STOP on
