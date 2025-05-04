-- Full backup of LabDb to a timestamped file, then verify it.
-- The path is on the SQL Server host (the container), not on whoever runs sqlcmd.
-- Usage: sqlcmd ... -v BACKUP_DIR=/backups -i sql/backup.sql
SET NOCOUNT ON;

DECLARE @dir  nvarchar(200) = N'$(BACKUP_DIR)';
DECLARE @file nvarchar(260) = @dir + N'/LabDb_' + FORMAT(SYSUTCDATETIME(), N'yyyyMMdd_HHmmss') + N'.bak';

PRINT CONCAT(N'Backing up LabDb to ', @file);

BACKUP DATABASE [LabDb]
TO DISK = @file
WITH COMPRESSION, CHECKSUM, INIT, STATS = 10;

RESTORE VERIFYONLY FROM DISK = @file WITH CHECKSUM;

PRINT N'Backup finished and verified.';
