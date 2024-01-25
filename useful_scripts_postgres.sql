-- delete rows from one table and insert them into another table in one statement
WITH deleted_rows AS (
  DELETE FROM table1
  WHERE condition
  RETURNING *
)
INSERT INTO table2
SELECT * FROM deleted_rows;

-- CHECK BIGGEST TABLES
SELECT
  schema_name,
  relname,
  pg_size_pretty(table_size) AS size,
  table_size
FROM (
       SELECT
         pg_catalog.pg_namespace.nspname           AS schema_name,
         relname,
         pg_relation_size(pg_catalog.pg_class.oid) AS table_size
       FROM pg_catalog.pg_class
         JOIN pg_catalog.pg_namespace ON relnamespace = pg_catalog.pg_namespace.oid
     ) t
WHERE schema_name NOT LIKE 'pg_%'
ORDER BY table_size desc
;
