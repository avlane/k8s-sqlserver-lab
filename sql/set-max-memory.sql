-- Usage: sqlcmd -S ... -i sql/set-max-memory.sql -v MAX_MEMORY_MB=3072
EXEC sys.sp_configure N'show advanced options', 1;
RECONFIGURE;
EXEC sys.sp_configure N'max server memory (MB)', $(MAX_MEMORY_MB);
RECONFIGURE;
SELECT name, CONVERT(bigint, value_in_use) AS value_in_use_mb
FROM sys.configurations
WHERE name = N'max server memory (MB)';
