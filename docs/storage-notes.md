# Storage notes

What I would want to know about the storage under `/var/opt/mssql` before trusting it.

- **Access mode.** `ReadWriteOnce` fits a single instance. A second Pod on another node cannot attach the same volume,
  which also explains why the restore test restores on the same server rather than starting a scratch instance next to it.
- **Latency.** A database cares about fsync latency far more than throughput. Network-attached or replicated volumes can look fine on
  a bandwidth test and still be slow for the log. Check `sys.dm_io_virtual_file_stats` (average write stall per file) before blaming SQL.
- **Local path provisioners** (the default in kind and minikube) are single-node and give no protection when the node dies.
- **Expansion.** Needs `allowVolumeExpansion: true` on the StorageClass and a driver that supports it. Some drivers need the Pod restarted for the filesystem resize.
- **Volume snapshots** (CSI) give crash-consistent copies at best. Without freezing I/O or using SQL Server's snapshot backup features, a restored snapshot goes through crash recovery; usually fine, but it is not a replacement for `BACKUP DATABASE` with `CHECKSUM`.
- **Reclaim policy.** For the data class prefer `Retain`; the default for dynamically provisioned volumes is usually `Delete`, so deleting the PVC deletes the database.
- **Separate volumes for data, log and tempdb** is standard advice on big servers. This lab uses one volume for `/var/opt/mssql` (data, log, tempdb, errorlog) plus the backup volume.
- **Backups on the same storage backend** share its failure modes; copy them somewhere else.
