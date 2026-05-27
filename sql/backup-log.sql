-- Transaction log backup of LabDb. Needs the FULL (or BULK_LOGGED) recovery model and an earlier full backup;
-- otherwise SQL Server raises error 4214 and, with sqlcmd -b, the Job fails, which is the signal we want.
-- Usage: sqlcmd ... -v BACKUP_DIR=/backups -i sql/backup-log.sql
SET NOCOUNT ON;

DECLARE @file nvarchar(260) = N'$(BACKUP_DIR)/LabDb_' + FORMAT(SYSUTCDATETIME(), N'yyyyMMdd_HHmmss') + N'.trn';

PRINT CONCAT(N'Backing up the LabDb log to ', @file);

BACKUP LOG [LabDb]
TO DISK = @file
WITH COMPRESSION, CHECKSUM, INIT, STATS = 25;

PRINT N'Log backup finished.';
