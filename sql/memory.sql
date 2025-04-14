-- Memory settings and usage as SQL Server sees them.
SET NOCOUNT ON;

SELECT c.name, CONVERT(bigint, c.value_in_use) AS value_in_use_mb
FROM sys.configurations AS c
WHERE c.name IN (N'max server memory (MB)', N'min server memory (MB)');

SELECT pm.physical_memory_in_use_kb / 1024 AS process_memory_in_use_mb,
       pm.memory_utilization_percentage,
       pm.process_physical_memory_low,
       pm.process_virtual_memory_low
FROM sys.dm_os_process_memory AS pm;

SELECT sm.total_physical_memory_kb / 1024     AS total_physical_mb,
       sm.available_physical_memory_kb / 1024 AS available_physical_mb,
       sm.system_memory_state_desc
FROM sys.dm_os_sys_memory AS sm;

SELECT si.cpu_count,
       si.physical_memory_kb / 1024    AS physical_memory_mb,
       si.committed_kb / 1024          AS committed_mb,
       si.committed_target_kb / 1024   AS committed_target_mb
FROM sys.dm_os_sys_info AS si;
