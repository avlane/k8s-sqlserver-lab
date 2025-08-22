# Troubleshooting

Symptom first.

| symptom | likely cause | check |
|---|---|---|
| Pod `CrashLoopBackOff`, log mentions the EULA | `ACCEPT_EULA` missing or not `Y` | `kubectl -n sqllab logs sqlserver-0 --previous` |
| `CrashLoopBackOff`, log mentions the password | SA password fails the policy | the Secret value (length and character classes) |
| `CrashLoopBackOff`, `Permission denied` under /var/opt/mssql | volume not writable by UID 10001 | `fsGroup`, storage class behaviour (pitfall 6) |
| `OOMKilled`, exit 137 | container memory limit smaller than SQL's real use | limit vs `max server memory` (resource-tuning.md) |
| Pod `Running` but `0/1` for a long time | probe cannot log in or `sqlcmd` not found | `kubectl describe pod`, then `kubectl exec sqlserver-0 -- ls /opt` |
| Pod `Pending`, event about PVC | no default StorageClass, or the class waits for the first consumer | `kubectl get pvc,sc -n sqllab` |
| Backup Job `Complete` but no file | `sqlcmd` ran without `-b` and the SQL error was swallowed | Job logs; the file is under `/backups` inside `sqlserver-0` |
| Backup Job failing with "Cannot open backup device" | the path is on the server side and not writable or not mounted | `kubectl exec sqlserver-0 -- ls -ld /backups` |
| Error 9002 in the SQL log | transaction log full: FULL recovery model without log backups | `sys.databases.log_reuse_wait_desc` |
| Client: "certificate chain was issued by an authority that is not trusted" | ODBC Driver 18 / tools 18 encrypt by default and the server certificate is self-signed | `-C` for sqlcmd, `TrustServerCertificate=yes` for a test connection string |

## Looking inside

    kubectl -n sqllab logs sqlserver-0                         # SQL Server writes its error log to stdout too
    kubectl -n sqllab exec sqlserver-0 -- ls /var/opt/mssql/log
    kubectl -n sqllab exec -it sqlserver-0 -- bash
    kubectl -n sqllab describe pod sqlserver-0                 # events, probe failures, OOMKilled
    kubectl -n sqllab get events --sort-by=.lastTimestamp

## Is it the Service or the server?

    kubectl -n sqllab get endpointslices -l kubernetes.io/service-name=sqlserver
    kubectl -n sqllab port-forward pod/sqlserver-0 1433:1433     # bypasses the Service

If the port-forward to the Pod works and the Service does not, look at the selector and at readiness (an unready Pod is not an endpoint).
