-- Restores the newest full backup of LabDb as LabDb_restoretest, checks it, drops it.
-- This restores on the SAME instance, so it proves the file restores, not that you could rebuild elsewhere.
SET NOCOUNT ON;

DECLARE @bsid int, @file nvarchar(260);

SELECT TOP (1) @bsid = bs.backup_set_id, @file = mf.physical_device_name
FROM msdb.dbo.backupset AS bs
JOIN msdb.dbo.backupmediafamily AS mf ON mf.media_set_id = bs.media_set_id
WHERE bs.database_name = N'LabDb' AND bs.type = 'D'
ORDER BY bs.backup_finish_date DESC;

IF @file IS NULL
    THROW 50001, N'No full backup of LabDb found in msdb.', 1;

PRINT CONCAT(N'Restoring ', @file);

-- Build the MOVE clauses from the logical file names recorded in msdb, so the script does not
-- depend on what the files in the source database happen to be called.
DECLARE @data nvarchar(260) = CONVERT(nvarchar(260), SERVERPROPERTY('InstanceDefaultDataPath'));
DECLARE @log  nvarchar(260) = CONVERT(nvarchar(260), SERVERPROPERTY('InstanceDefaultLogPath'));
DECLARE @move nvarchar(max);

SELECT @move = STRING_AGG(
           CONVERT(nvarchar(max), N', MOVE N''')
           + REPLACE(f.logical_name, N'''', N'''''')
           + N''' TO N'''
           + REPLACE(CASE f.file_type WHEN 'L' THEN @log ELSE @data END, N'''', N'''''')
           + N'LabDb_restoretest_' + CONVERT(nvarchar(10), f.file_number)
           + CASE f.file_type WHEN 'L' THEN N'.ldf' ELSE N'.mdf' END
           + N'''', N'') WITHIN GROUP (ORDER BY f.file_number)
FROM msdb.dbo.backupfile AS f
WHERE f.backup_set_id = @bsid;

DECLARE @sql nvarchar(max) =
    N'RESTORE DATABASE [LabDb_restoretest] FROM DISK = N''' + REPLACE(@file, N'''', N'''''')
    + N''' WITH CHECKSUM, REPLACE, STATS = 25' + @move + N';';

BEGIN TRY
    EXEC sys.sp_executesql @sql;

    DBCC CHECKDB (N'LabDb_restoretest') WITH NO_INFOMSGS;

    DECLARE @source bigint, @copy bigint;
    SELECT @source = COUNT_BIG(*) FROM LabDb.dbo.Orders;
    SELECT @copy   = COUNT_BIG(*) FROM LabDb_restoretest.dbo.Orders;
    PRINT CONCAT(N'Rows in source: ', @source, N', rows in restored copy: ', @copy);

    -- The backup is older than "now", so the copy may have fewer rows, but never more, and not none.
    IF @copy = 0 OR @copy > @source
        THROW 50002, N'Restored row count looks wrong.', 1;
END TRY
BEGIN CATCH
    IF DB_ID(N'LabDb_restoretest') IS NOT NULL
        DROP DATABASE [LabDb_restoretest];
    THROW;
END CATCH;

DROP DATABASE [LabDb_restoretest];
PRINT N'Restore test passed.';
