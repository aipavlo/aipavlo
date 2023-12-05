-- CHECK STORED PROCEDURES
SELECT * FROM v_catalog.user_procedures;

-- GENERATE STATEMENTS AND EXECUTE EVERY ROW
DO $$
DECLARE
	c CURSOR FOR 
	SELECT 
    'INSERT INTO metadata.license_usage (metadata_id, schema_name, table_name, column_name, column_audit) SELECT (SELECT id FROM metadata.sessions WHERE session_id = (SELECT session_id FROM current_session)) as metadata_id,'||table_schema||' AS SCHEMA_NAME, '||table_name||' as TABLE_NAME, '||column_name||' AS COLUMN_NAME, (SELECT SUM(AUDIT_LENGTH('||column_name||')) FROM '||table_schema||'.'||table_name||') AS AUDIT_SUM ;'
    FROM v_catalog.columns
    WHERE table_schema IN ('schema_name') ;
	query_ varchar(65000);
BEGIN
	FOR query_ IN CURSOR c LOOP
	   EXECUTE query_;
	END LOOP;
END;
$$;
