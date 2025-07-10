# Pitfalls

Things that stop the container from starting, in the order I expect to hit them.

## 1. `ACCEPT_EULA` is mandatory

The image refuses to start unless `ACCEPT_EULA=Y` is set. That variable is a statement that you accepted the
license terms, so read them once instead of copy-pasting the line. The container logs a message about the EULA and exits;
on Kubernetes that shows as `CrashLoopBackOff` with a log that is easy to miss, because the container only lives for a moment.

    kubectl -n sqllab logs sqlserver-0 --previous

## 2. The SA password has to pass the password policy

At least 8 characters, from three of the four categories (upper, lower, digits, symbols). Otherwise the
server shuts down right after start-up with a message about the password not meeting the policy. Same symptom as above:
CrashLoopBackOff. The password comes from the Secret `sqlserver-sa`.

## 3. Use `MSSQL_SA_PASSWORD`, not `SA_PASSWORD`

`SA_PASSWORD` is the older, deprecated name. The first version of the StatefulSet in this repo used it. It is
replaced in a later commit.

## 4. Memory floor

SQL Server on Linux needs at least about 2 GB of RAM available to the process. A container limit at or just
above that is not a comfortable fit (see `resource-tuning.md`). When the process is killed for
exceeding the limit the Pod shows `OOMKilled` and exit code 137.

## 5. Editions and licensing

`MSSQL_PID` chooses the edition (`Developer`, `Express`, `Standard`, `Enterprise`, `Web` or a product key).
Developer has Enterprise features but may not be used in production. Express is free with resource caps. The others
need paid licenses, and licensing in containers and Kubernetes has its own rules (cores, not Pods). I am not the
person to interpret that; check with whoever owns your license agreement before running anything real.

## 6. Volume permissions (fsGroup)

Since SQL Server 2019 the image runs as a non-root user (`mssql`, UID 10001), not root. A freshly provisioned
volume is typically owned by root, so the first start can fail with permission errors when SQL Server tries to
create files under `/var/opt/mssql` (the log shows `Access denied` / `Permission denied`; the Pod restarts in a loop).
The first version of the StatefulSet had no `securityContext`.

`fsGroup: 10001` on the Pod makes the kubelet set the group of the volume contents to that GID and make them
group-writable, when the storage driver supports it. Not every driver honours `fsGroup`. If yours does not, you need an
init container that runs `chown`, which means running something as root and is worth avoiding.

## 7. Probes with sqlcmd

The first readiness probe passed `-P $(MSSQL_SA_PASSWORD)` to `sqlcmd` and would never have worked:

- A probe's `exec.command` is run directly, not through a shell, and (as far as I understand the docs) `$(VAR)`
  references are not expanded there the way they are for a container's own `command`/`args`. `sqlcmd` would receive the
  literal text `$(MSSQL_SA_PASSWORD)` as the password and fail to log in, so the Pod would stay `0/1` forever.
- Even if it expanded, a password on a command line is visible in the process list. `sqlcmd` reads the `SQLCMDPASSWORD` environment variable instead, and the StatefulSet now sets it from the same Secret.
- The tools directory depends on the image: `/opt/mssql-tools/bin` on older images, `/opt/mssql-tools18/bin` on newer
  ones (tools 18 is where `-C`, trust the server certificate, matters because encryption is on by default). I do not know which one the CU16 image has, so the probe tries both. Check with `kubectl exec sqlserver-0 -- ls /opt`.

The probes now split the jobs:

| probe | what it does | why |
|---|---|---|
| startup | `SELECT 1` via sqlcmd, up to 30 x 10s | recovery after a crash can take minutes; holds off the other two |
| readiness | `SELECT 1` via sqlcmd | take the Pod out of the Service when it cannot answer a query |
| liveness | TCP connect to 1433 | cheap; a liveness probe that runs queries can restart a busy but healthy server |

## 8. The helper Pods do not need to be root

The backup and restore-test Pods only run `sqlcmd`, so they run as UID 10001 (the `mssql` user baked into the image)
with `allowPrivilegeEscalation: false`, all capabilities dropped and the runtime's default seccomp profile.
`runAsNonRoot: true` works here only because `runAsUser` is set explicitly; the image's default user is `mssql`,
but being explicit avoids relying on that.

The SQL Server Pod itself is **not** hardened beyond `fsGroup`: I do not know which capabilities and syscalls the
engine needs, and dropping them blind would be a good way to get a crash loop with a confusing log. If you try it, change one thing at a time.
