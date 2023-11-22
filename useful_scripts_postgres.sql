-- delete rows from one table and insert them into another table in one statement
WITH deleted_rows AS (
  DELETE FROM table1
  WHERE condition
  RETURNING *
)
INSERT INTO table2
SELECT * FROM deleted_rows;
