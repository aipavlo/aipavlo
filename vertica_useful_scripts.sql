--- STATISTICS ---
SELECT AUDIT('public.table_name', 'table', 0, 100);
SELECT ANALYZE_STATISTICS('public.table_name');
SELECT GET_COMPLIANCE_STATUS(); -- check vertica actual audit status 
SELECT AUDIT_LICENSE_SIZE(); -- trigger an immediate audit

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


-- DDL
-- CHECK ENABLED AND DISABLED CONSTRAINTS
SELECT CONSTRAINT_NAME, CONSTRAINT_TYPE, IS_ENABLED FROM V_CATALOG.TABLE_CONSTRAINTS
WHERE TABLE_NAME = 'table_name' AND CONSTRAINT_SCHEMA_ID = (SELECT SCHEMA_ID FROM V_CATALOG.SCHEMATA WHERE SCHEMA_NAME = 'schema_name');
-- ADD CONSTRAINT
ALTER TABLE schema_name.table_name ADD CONSTRAINT constraint_name PRIMARY KEY (column_name1, column_name2, ...) ENABLED;
-- ENABLE/DISABLE CONSTRAINT
ALTER TABLE schema_name.table_name ALTER CONSTRAINT table_name_PK ENABLED; -- DISABLED

-- VSQL
-- stop on error
\set ON_ERROR_STOP on


