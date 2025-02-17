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
above that is not a comfortable fit (see the resource tuning notes once they exist). When the process is killed for
exceeding the limit the Pod shows `OOMKilled` and exit code 137.

## 5. Editions and licensing

`MSSQL_PID` chooses the edition (`Developer`, `Express`, `Standard`, `Enterprise`, `Web` or a product key).
Developer has Enterprise features but may not be used in production. Express is free with resource caps. The others
need paid licenses, and licensing in containers and Kubernetes has its own rules (cores, not Pods). I am not the
person to interpret that; check with whoever owns your license agreement before running anything real.
