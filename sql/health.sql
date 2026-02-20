-- Quick health snapshot. Read-only.
SET NOCOUNT ON;

SELECT @@SERVERNAME                          AS server_name,
       SERVERPROPERTY('ProductVersion')      AS product_version,
       SERVERPROPERTY('ProductLevel')        AS product_level,
       SERVERPROPERTY('ProductUpdateLevel')  AS update_level,
       SERVERPROPERTY('Edition')             AS edition;

-- Databases, recovery model and what is stopping log truncation
SELECT d.name, d.state_desc, d.recovery_model_desc, d.log_reuse_wait_desc
FROM sys.databases AS d
ORDER BY d.name;

-- File sizes of user databases
SELECT DB_NAME(mf.database_id) AS database_name, mf.name AS logical_name, mf.type_desc,
       mf.size * 8 / 1024 AS size_mb, mf.physical_name
FROM sys.master_files AS mf
WHERE mf.database_id > 4
ORDER BY database_name, mf.file_id;

-- Newest full and log backup per user database (NULL means never)
SELECT d.name,
       MAX(CASE WHEN bs.type = 'D' THEN bs.backup_finish_date END) AS last_full_backup,
       MAX(CASE WHEN bs.type = 'L' THEN bs.backup_finish_date END) AS last_log_backup
FROM sys.databases AS d
LEFT JOIN msdb.dbo.backupset AS bs ON bs.database_name = d.name
WHERE d.database_id > 4
GROUP BY d.name;

-- Top waits since start-up, without the usual idle ones
SELECT TOP (10) ws.wait_type, ws.waiting_tasks_count, ws.wait_time_ms
FROM sys.dm_os_wait_stats AS ws
WHERE ws.wait_type NOT IN (N'SLEEP_TASK', N'LAZYWRITER_SLEEP', N'XE_TIMER_EVENT', N'XE_DISPATCHER_WAIT',
                           N'REQUEST_FOR_DEADLOCK_SEARCH', N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
                           N'BROKER_TO_FLUSH', N'BROKER_TASK_STOP', N'CLR_AUTO_EVENT', N'DISPATCHER_QUEUE_SEMAPHORE',
                           N'FT_IFTS_SCHEDULER_IDLE_WAIT', N'HADR_FILESTREAM_IOMGR_IOCOMPLETION',
                           N'SP_SERVER_DIAGNOSTICS_SLEEP', N'WAITFOR', N'DIRTY_PAGE_POLL', N'CHECKPOINT_QUEUE')
  AND ws.waiting_tasks_count > 0
ORDER BY ws.wait_time_ms DESC;
