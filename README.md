# k8s-sqlserver-lab

A learning lab for running SQL Server in a container on Kubernetes: a StatefulSet with
a PersistentVolumeClaim, a Secret for the SA password, a Service, probes that use
`sqlcmd`, a backup CronJob and a restore-test Job. The point is to understand the moving parts and
write down the pitfalls, not to provide a production recipe.

## Layout

- `kustomization.yaml`: renders the lab (`kubectl kustomize .`), pins the image tag and generates the `sql-scripts` ConfigMap
- `manifests/`: Kubernetes YAML: namespace, Secret example, StatefulSet, Services, backup PVC, backup CronJob, restore-test Job, NetworkPolicy
- `sql/`: T-SQL for initialisation, memory, backup and the restore test
- `docs/`: pitfalls, resource tuning, backup and restore, upgrades, troubleshooting, and the availability group discussion
- `scripts/check_lab.py`: consistency check across the manifests

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
Expected: one row starting with `Microsoft SQL Server 2022 (RTM-CU19) ...`.

## Create the sample database

    kubectl -n sqllab port-forward service/sqlserver 1433:1433 &
    sqlcmd -S localhost,1433 -U sa -C -i sql/init.sql

Expected: `OrderRows` is `1000`. Running it a second time changes nothing.
The new database gets its recovery model from `model`, which is FULL by default. See the backup notes later: a FULL
database with no log backups never truncates its log.

## Rendering with kustomize

    kubectl kustomize .                 # renders everything; needs no cluster
    kubectl apply -k .                  # applies it (the Secret is applied separately)

The image tag is set in one place, the `images:` block of `kustomization.yaml`, which overrides the tag written in
the StatefulSet. To change the SQL Server version, change that block. The tag in the StatefulSet is only the
starting point and goes stale, so treat `kubectl kustomize .` output as the truth.

## Consistency check

    python3 scripts/check_lab.py

Checks (text level only, no cluster, no YAML library): Secret names and keys, generated ConfigMap names, PVC names, Service
selectors against the StatefulSet Pod labels, CronJob `concurrencyPolicy`, pinned image tags.
It cannot tell whether a manifest is valid Kubernetes; `kubectl kustomize .` is the other check that can be run without a cluster.

## Who can connect

`manifests/networkpolicy.yaml` allows TCP 1433 into the SQL Server Pod only from Pods labelled
`sql.example/client: "true"`; the backup and restore-test Pods carry that label. With a CNI that enforces NetworkPolicy, the
`kubectl port-forward` used above is **not** affected, because it goes through the API server and kubelet and not through the Pod network; that is
convenient and also means port-forward is a way around the policy for anyone with the RBAC permission to use it.
With a CNI that does not enforce policies the object does nothing.
Tests for the checker itself: `python3 -m unittest discover -s tests`.
