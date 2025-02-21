# k8s-sqlserver-lab

A learning lab for running SQL Server in a container on Kubernetes: a StatefulSet with
a PersistentVolumeClaim, a Secret for the SA password, a Service, probes that use
`sqlcmd`, a backup CronJob and a restore-test Job. The point is to understand the moving parts and
write down the pitfalls, not to provide a production recipe.

## Layout

- `manifests/`: Kubernetes YAML (namespace, Secret example, StatefulSet, Services)
- `docs/`: notes and pitfalls

## Try it

    kubectl apply -f manifests/namespace.yaml
    cp manifests/secret.example.yaml sqlserver-sa.secret.yaml     # edit the password; git ignores this file
    kubectl apply -f sqlserver-sa.secret.yaml
    kubectl apply -f manifests/sqlserver-service.yaml -f manifests/sqlserver-statefulset.yaml
    kubectl -n sqllab get pods --watch
    kubectl -n sqllab logs sqlserver-0

Expected: `sqlserver-0` goes Pending, ContainerCreating, then Running. The log ends with
`SQL Server is now ready for client connections. This is an informational message; no user action is required.`
after startup finishes, which can take a minute or more the first time.

Connect from your machine:

    kubectl -n sqllab port-forward service/sqlserver 1433:1433
    sqlcmd -S localhost,1433 -U sa -C -Q "SELECT @@VERSION"

(or use Azure Data Studio or SSMS against `localhost,1433`; `-C` trusts the container's self-signed certificate.)
Expected: one row starting with `Microsoft SQL Server 2022 (RTM-CU15) ...`.

## Create the sample database

    kubectl -n sqllab port-forward service/sqlserver 1433:1433 &
    sqlcmd -S localhost,1433 -U sa -C -i sql/init.sql

Expected: `OrderRows` is `1000`. Running it a second time changes nothing.
The new database gets its recovery model from `model`, which is FULL by default. See the backup notes later: a FULL
database with no log backups never truncates its log.
