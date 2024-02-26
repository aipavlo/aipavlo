SELECT
  pg_stat_activity.pid AS process_id,
  pg_locks.locktype AS lock_type,
  pg_locks.database AS database_id,
  pg_locks.relation AS relation_id,
  pg_locks.page AS page_number,
  pg_locks.virtualxid AS virtual_transaction_id,
  pg_locks.transactionid AS transaction_id,
  pg_stat_activity.query AS query
FROM
  pg_stat_activity
JOIN
  pg_locks
ON
  pg_stat_activity.pid = pg_locks.pid;
