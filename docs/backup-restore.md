# Backup and restore

## Where the backup file ends up

`BACKUP DATABASE ... TO DISK = '/backups/x.bak'` is executed **by the SQL Server process**, so `/backups` is a path
inside the SQL Server container, not in the Pod that runs `sqlcmd`. That is why the backup PVC is mounted in
`sqlserver-0` and the CronJob only needs network access and the SA password. A CronJob that mounted the volume itself would be backing up to a
folder SQL Server cannot see.

## What the CronJob does

1. Starts a Pod from the same image (it contains `sqlcmd`; a smaller tools image would be lighter).
2. Runs `sql/backup.sql` through the `sqlserver` Service: `BACKUP DATABASE ... WITH COMPRESSION, CHECKSUM, INIT`
   followed by `RESTORE VERIFYONLY ... WITH CHECKSUM`.

## What this does not give you

- **A restore test.** `VERIFYONLY` proves the file is readable and its checksums match, not that it restores. The restore-test Job (later) does that.
- **Off-cluster copies.** The backups sit on a PVC in the same cluster as the database. Losing the cluster or the storage backend loses both.
- **Retention.** Nothing deletes old files; the 10Gi PVC will fill up.
- **Point-in-time recovery.** Only full backups are taken. A FULL recovery model database also needs transaction log backups, or its log grows until the disk is full (error 9002).

## Reading the result

Expected output, in `kubectl -n sqllab logs job/<job>`:

    Backing up LabDb to /backups/LabDb_20250518_020000.bak
    10 percent processed.
    ...
    Backup finished and verified.
