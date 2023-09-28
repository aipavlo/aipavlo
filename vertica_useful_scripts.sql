SELECT EXPORT_OBJECTS( '', 'schema_name.table_name') ; -- export DDL

SELECT CLOSE_ALL_SESSIONS(); -- close all sessions except during session

SELECT AUDIT('public.table_name', 'table', 0, 100);
SELECT ANALYZE_STATISTICS('public.table_name');
SELECT GET_COMPLIANCE_STATUS(); -- check vertica actual audit status 
SELECT AUDIT_LICENSE_SIZE(); -- trigger an immediate audit

-- CHECK ALL PROJECTIONS
SELECT * FROM v_catalog.projections WHERE projection_schema = 'schema_name' AND anchor_table_name = 'table_name';
-- CHECK ALL ROS CONTAINERS
SELECT * FROM storage_containers
WHERE SCHEMA_name = 'schema_name' and projection_name like 'table_name%';
-- SELECT EXECTLY 1 CONTAINER (CHOOSE FROM PREVIOUS RESULT)
SELECT * FROM table_name.schema_name 
WHERE lead_storage_oid() = '45035996283468437';

-- CHECK ACTIVE SESSIONS
SELECT * FROM v_monitor.query_requests WHERE user_name = 'dbadmin' AND is_executing = 'True';
