--- STATISTICS ---
SELECT AUDIT('public.table_name', 'table', 0, 100);
SELECT AUDIT_FLEX('flex.table_name');
SELECT ANALYZE_STATISTICS('public.table_name');
SELECT GET_COMPLIANCE_STATUS(); -- check vertica actual audit status 
SELECT AUDIT_LICENSE_SIZE(); -- trigger an immediate audit
SELECT /*+DEPOT_FETCH(NONE)*/ (SUM(AUDIT_LENGTH(column_name)) )FROM schema_name.table_name;
SELECT APPROXIMATE_COUNT_DISTINCT(column_name) FROM schema_name.table_name;
-- RESOURCE POOL
SELECT pool_name, node_name, max_query_memory_size_kb, max_memory_size_kb, memory_size_actual_kb FROM V_MONITOR.RESOURCE_POOL_STATUS WHERE pool_name='general';
SELECT name, memorysize, maxmemorysize FROM V_CATALOG.RESOURCE_POOLS;
SELECT COUNT(1) FROM NODES WHERE NODE_STATE = 'UP';

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

-- BIGGEST TABLES ACCORDING TO PHYSICAL STORAGE
SELECT anchor_table_name, SUM(used_bytes) AS raw_data_size
FROM v_monitor.projection_storage
WHERE anchor_table_schema = 'schema_name'
GROUP BY anchor_table_name
ORDER BY 2 DESC;

-- GENERATE SCRIPT FOR AUDIT ALL COLUMNS OF SCHEMA
SELECT 
'SELECT '''||column_name||''' AS COLUMN_NAME, '''||table_schema||'.'||table_name||''' as TABLE_NAME, (SELECT SUM(AUDIT_LENGTH('||column_name||')) FROM '||table_schema||'.'||table_name||') AS AUDIT_SUM UNION ALL'
FROM v_catalog.columns
WHERE table_schema = 'schema_name';

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
ALTER TABLE schema_name.table_name ALTER COLUMN column_name SET DEFAULT NEXTVAL('schema_name.sequence_name');
-- FLATTEN TABLE REBUILD WITH PARTITION
SELECT REFRESH_COLUMNS ('schema_name.table_name', 'column_name1', 'REBUILD',
TO_CHAR(ADD_MONTHS(current_date, -2),'YYYYMM'),
TO_CHAR(ADD_MONTHS(current_date, -2),'YYYYMM'));
-- CREATE NEW UNSEGMENTED PROJECTION AND DROP OLD SEGMENTED
CREATE PROJECTION schema_name.table_name_super_0 AS SELECT * FROM schema_name.table_name ORDER BY table_name.column_with_id UNSEGMENTED ALL NODES;		
SELECT REFRESH('schema_name.table_name');
SELECT MAKE_AHM_NOW(); -- Move the AHM to the most recent safe epoch
DROP PROJECTION schema_name.table_name_super;


--- FLEX TABLE ---
--DROP TABLE IF EXISTS flex.dwh_flex;
CREATE FLEX TABLE IF NOT EXISTS flex.dwh_flex();
COPY flex.dwh_flex FROM '/file_to_import/dwh.csv.gz' GZIP PARSER fcsvparser();
COPY flex.dwh_flex FROM '/file_to_import/dwh.csv' PARSER fcsvparser(delimiter=',');
SELECT maplookup(__raw__, 'request_id') AS request_id FROM flex.dwh_flex;
SELECT COMPUTE_FLEXTABLE_KEYS_AND_BUILD_VIEW('flex.dwh_flex');
--DROP TABLE IF EXISTS src.dwh_table;
CREATE TABLE IF NOT EXISTS src.dwh_table AS SELECT * FROM flex.dwh_flex_view;


--- SELECT STATEMENT ---
--varchar to timestamp
CASE 
	WHEN ts LIKE '20%' OR ts LIKE '19%' THEN TO_TIMESTAMP(ts, 'YYYYMMDDHH24MISS') 
	WHEN ts LIKE '____-__-__T__:__:__%__:__' THEN 
		TO_TIMESTAMP(LEFT(ts, 19), 'YYYY-MM-DD"T"HH24:MI:SS') +
		(CASE WHEN RIGHT(ts, 6) LIKE '+%' THEN 1 ELSE -1 END * TO_NUMBER(SUBSTRING(ts, 21, 2)))/24
	WHEN ts LIKE '____-__-__ __:__:__' THEN TO_TIMESTAMP(ts, 'YYYY-MM-DD HH24:MI:SS') 
	ELSE NULL
END
--COUNT HASH OF COLUMNS
SELECT COUNT(HASH(column1, column2, column3, column4)) FROM your_table;
--CHECK IF NOT EXISTS AND HANDLE WITH NULL
NOT EXISTS (SELECT 1 FROM schema_name.table_name t WHERE COALESCE(s.id::varchar, 'default_value_for_duplicates') = COALESCE(t.id::varchar, 'default_value_for_duplicates'))


--- MERGE STATEMENT ---
MERGE INTO schema_name.target_table AS t2 
USING (SELECT col_pk, col1, col2, Metadata FROM schema_name.source_table) AS t1
ON t2.col_pk = t1.col_pk
WHEN MATCHED THEN
    UPDATE SET col1 = t1.col1,
               col2 = t1.col2
WHEN NOT MATCHED THEN 
    INSERT (col1, col2, Metadata)
    VALUES (t1.col1, t1.col2, Metadata);


--- VSQL ---
-- stop on error
\set ON_ERROR_STOP on
-- :!! # Executes a shell command and returns the output to vsql.
vsql -A -t -d your_database -U your_user -h your_host -w your_password -f /file_to_import/adhoc.sql -o /file_to_import/result.txt -- execute script and have all output in file withou header and footer
