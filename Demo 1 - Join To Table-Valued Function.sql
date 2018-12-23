/* Example 1:  joining to table-valued functions. */
/* What we want:  the latest execution plan for each connection. */

--sys.dm_exec_connections gives basic session information
SELECT
	*
FROM sys.dm_exec_connections c;

SELECT
	c.session_id,
	c.connect_time,
	c.num_reads,
	c.num_writes,
	t.text
FROM sys.dm_exec_connections c
	CROSS APPLY sys.dm_exec_sql_text(c.most_recent_sql_handle) t;

/* What is the difference between cross apply and outer apply? */
--NOTE:  change c.session_id to a relevant value before running this.
--You can get relevant values from the first query above.
SELECT
	c.session_id,
	c.connect_time,
	c.num_reads,
	c.num_writes,
	t.text
FROM sys.dm_exec_connections c
	OUTER APPLY sys.dm_exec_sql_text(
					CASE 
						WHEN c.session_id = 57 THEN NULL 
						ELSE c.most_recent_sql_handle 
					END) t
ORDER BY
	c.session_id ASC;

--Note that when running CROSS APPLY, your session no longer shows up.
SELECT
	c.session_id,
	c.connect_time,
	c.num_reads,
	c.num_writes,
	t.text
FROM sys.dm_exec_connections c
	CROSS APPLY sys.dm_exec_sql_text(
					CASE 
						WHEN c.session_id = 57 THEN NULL 
						ELSE c.most_recent_sql_handle 
					END) t
ORDER BY
	c.session_id ASC;