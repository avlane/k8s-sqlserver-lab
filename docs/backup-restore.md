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

## Why the CronJob looks the way it does

The first version just ran `sqlcmd -i backup.sql`. Problems I expect with that:

- **A failed backup looks like a success.** Without `-b`, `sqlcmd` prints the error and still exits 0, so the Job is `Complete`. With `-b` any SQL error gives a non-zero exit code and the Job fails (and shows in `kubectl get jobs`).
- **The tools path.** `/opt/mssql-tools18/bin/sqlcmd` was hard-coded; the script now looks for both locations.
- **Overlap.** `concurrencyPolicy: Forbid` skips a run when the previous one is still going.
- **Missed runs and piles of Jobs.** `startingDeadlineSeconds`, history limits, `activeDeadlineSeconds` and `ttlSecondsAfterFinished` bound all of that.
- **Retries.** `backoffLimit: 2` retries a failing backup twice with back-off. A backup that fails because the server is down will fail all three times, which is fine; the Job is `Failed` and someone needs to look.
