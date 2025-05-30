-- Restores the newest full backup of LabDb as LabDb_restoretest, checks it, drops it.
-- This restores on the SAME instance, so it proves the file restores, not that you could rebuild elsewhere.
SET NOCOUNT ON;

DECLARE @file nvarchar(260) = (
    SELECT TOP (1) mf.physical_device_name
    FROM msdb.dbo.backupset AS bs
    JOIN msdb.dbo.backupmediafamily AS mf ON mf.media_set_id = bs.media_set_id
    WHERE bs.database_name = N'LabDb' AND bs.type = 'D'
    ORDER BY bs.backup_finish_date DESC);

IF @file IS NULL
    THROW 50001, N'No full backup of LabDb found in msdb.', 1;

PRINT CONCAT(N'Restoring ', @file);

RESTORE DATABASE [LabDb_restoretest]
FROM DISK = @file
WITH MOVE N'LabDb'     TO N'/var/opt/mssql/data/LabDb_restoretest.mdf',
     MOVE N'LabDb_log' TO N'/var/opt/mssql/data/LabDb_restoretest_log.ldf',
     CHECKSUM, REPLACE, STATS = 25;

DBCC CHECKDB (N'LabDb_restoretest') WITH NO_INFOMSGS;

DROP DATABASE [LabDb_restoretest];
PRINT N'Restore test passed.';
