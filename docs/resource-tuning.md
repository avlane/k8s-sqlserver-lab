# Resource tuning notes

These are the rules of thumb I found, and the reasoning for the values in the manifest.

## Memory: the container limit is not the SQL Server limit

The container memory limit is enforced by the kernel (cgroup). SQL Server has its own
`max server memory (MB)` setting, and that one only covers part of what the process uses. Memory outside it
(thread stacks, the CLR, extended stored procedures, columnstore and in-memory structures, the process itself) comes on top.

If `max server memory` is set close to the container limit, the process can exceed the limit and be killed
(`OOMKilled`, exit 137) even though SQL Server thinks it is within its own bounds. So:

- Pick the container limit first (this lab: `4Gi`).
- Set `max server memory` to roughly 70 to 75 percent of it (3072 MB for 4Gi) and leave the rest as headroom.
  `sql/set-max-memory.sql` does that; `sql/memory.sql` shows the effect.
- `MSSQL_MEMORY_LIMIT_MB` is an environment variable of the image that sets the memory limit SQL Server uses
  at start-up (it ends up in `mssql.conf`). The manifest sets it to 3072. I am treating it as a belt, with `sp_configure` as the braces.

The first version of the manifest had `limits.memory: 2Gi`, which is the documented minimum for SQL Server and so leaves
nothing for a working set. It is raised to 4Gi.

## Requests equal limits for memory

With `requests.memory == limits.memory` the Pod gets a better QoS class (Guaranteed if CPU is also equal, otherwise Burstable
with a fully reserved memory request). A database that is evicted under node memory pressure is worse than one that is not scheduled.
The manifest sets the memory request to the limit and only a CPU request.

## CPU

No CPU limit is set. A CFS quota throttles the process in 100 ms periods and a database can show latency spikes
even when the average usage is low. The request (`500m`) reserves capacity for scheduling.
Two open questions: whether `sys.dm_os_sys_info.cpu_count` reflects a CPU limit if one is set, and how
licensing cores are counted for a container whose limit is lower than the host's core count.

## Storage

The data PVC is 5Gi in the first versions. SQL Server's own growth settings (autogrowth of data and log files) will
fill it without warning; size the volume with headroom and watch `kubectl exec sqlserver-0 -- df -h /var/opt/mssql`.
