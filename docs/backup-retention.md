# Backup retention

Today nothing removes old `.bak` and `.trn` files from `/backups`. With a daily full backup and a log backup every 15 minutes
the 10Gi volume will fill up eventually, and when it does the backups start failing.

## Options I considered

1. **Delete from a Pod that mounts the volume.** `find /backups -name '*.bak' -mtime +7 -delete`. The volume is `ReadWriteOnce`, so such a Pod has to run on the same node as `sqlserver-0` (a pod affinity rule) or it cannot mount it. Or run the command with `kubectl exec sqlserver-0 -- ...` from a scheduled job that has RBAC rights to exec, which is more access than I like to hand out.
2. **Ship the files elsewhere first, then delete locally.** Needs an object store or another volume. Probably the real answer, because it also gives the off-cluster copy the backup notes ask for.
3. **Let SQL Server write to an object store directly** (`BACKUP ... TO URL`) and let the store's lifecycle rules expire files. Needs credentials, network egress and a suitable SQL Server version and configuration.
4. **Keep it manual** and watch `df -h /backups`. Fine for the lab, not for anything else.

Whatever is chosen has to keep **the chain** intact: deleting a full backup that later log backups depend on makes the logs useless. Delete in whole generations (a full backup and the logs that follow it), and never delete the newest full backup.
