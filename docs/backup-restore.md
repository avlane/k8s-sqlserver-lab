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

## Restore test

`manifests/restore-test-job.yaml` runs `sql/restore-test.sql`: find the newest full backup of `LabDb` in `msdb`,
restore it as `LabDb_restoretest`, run `DBCC CHECKDB`, compare row counts with the source table and drop the copy.

The first version hard-coded the logical file names (`LabDb`, `LabDb_log`) in the `MOVE` clauses. That works
only while the source database keeps exactly those names, and breaks the first time someone adds a filegroup. The current
script reads the file list for that backup set from `msdb.dbo.backupfile` and builds the clauses with `STRING_AGG`.
It also drops the half-restored copy when something fails, so a failed test does not leave a database behind that
makes the next run fail with "database exists" confusion (`REPLACE` covers most of that anyway).

Limits: it restores onto the same instance. A real disaster-recovery test restores onto a different server, with
nothing but the backup file and the documented procedure. It also trusts `msdb` history; if `msdb` is lost the script finds nothing.

Expected result: `Restore test passed.` and a Job in `Complete` state. If `CHECKDB` finds corruption the
errors are severity 16, so `sqlcmd -b` exits non-zero and the Job is `Failed`.

## Waiting for the server

If the restore test is applied right after a restart of `sqlserver-0` (an upgrade, for example) the Service has no ready
endpoint yet and `sqlcmd` fails to connect, which would fail the Job for a reason that has nothing to do with the backup. An init container
now retries `SELECT 1` every 5 seconds for up to 5 minutes first. The backup CronJob does not need this: it has `backoffLimit: 2` and a schedule that makes a missed run a non-event.

## Schedule

`0 2 * * *` with `timeZone: "Etc/UTC"` is 02:00 UTC. Without `timeZone` the CronJob follows the controller manager's time zone, which is usually UTC but not guaranteed. Pick a quiet hour for your workload; compressed full backups still cost I/O and CPU.
To pause backups, for example during an upgrade: `kubectl -n sqllab patch cronjob sqlserver-backup -p '{"spec":{"suspend":true}}'`.

## Log backups and the recovery model

`LabDb` inherits the FULL recovery model from `model`. In FULL, the transaction log is only truncated by a log backup, so
with full backups alone the log grows until the volume is full (error 9002, `log_reuse_wait_desc = LOG_BACKUP`). Options:

- take log backups (`sql/backup-log.sql`, scheduled by the next commit), which also allows restoring to a point in time, or
- switch the database to SIMPLE (`ALTER DATABASE LabDb SET RECOVERY SIMPLE`) if losing everything since the last full backup is acceptable.

The restore test only restores the latest **full** backup. It does not replay log backups, so it says nothing about point-in-time recovery.
