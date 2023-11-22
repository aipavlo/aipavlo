CREATE OR REPLACE PROCEDURE core_5.merge_tbl(anc_name varchar, merge_statement varchar(10000)) AS
$$
DECLARE 
rows_to_insert int;
rows_to_update int;
BEGIN
    EXECUTE '
SELECT 
COUNT(CASE WHEN to_insert = 1 THEN 1 END) AS rows_to_insert,
COUNT(CASE WHEN to_insert = 0 THEN 1 END) AS rows_to_update,
COUNT(CASE WHEN to_insert IS NULL THEN 1 END) AS rows_no_operation,
COUNT(1) AS rows_all
FROM v_temp_schema.t'|| QUOTE_IDENT(anc_name) into rows_to_insert, rows_to_update;
	IF rows_to_insert + rows_to_update > 0 THEN
		EXECUTE merge_statement;
		RAISE INFO '% rows inserted: %', anc_name, rows_to_insert;
		RAISE INFO '% rows updated: %', anc_name, rows_to_update;
	ELSE
		RAISE INFO 'no DML operations with %', anc_name;
	END IF;
END;
$$
