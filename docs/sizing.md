# Sizing profiles

Starting points, derived from the memory rules in `resource-tuning.md`.

| profile | container memory limit and request | `MSSQL_MEMORY_LIMIT_MB` / `max server memory` | CPU request | data PVC |
|---|---|---|---|---|
| small (laptop) | 3Gi | 2048 | 250m | 5Gi |
| default (the manifests) | 4Gi | 3072 | 500m | 5Gi |
| larger test | 8Gi | 6144 | 2 | 20Gi |

## Trying a profile without editing the manifests

    kubectl -n sqllab patch statefulset sqlserver --type=json -p '[
      {"op":"replace","path":"/spec/template/spec/containers/0/resources/requests/memory","value":"8Gi"},
      {"op":"replace","path":"/spec/template/spec/containers/0/resources/limits/memory","value":"8Gi"},
      {"op":"replace","path":"/spec/template/spec/containers/0/env/2/value","value":"6144"}
    ]'

The `env/2` index depends on the order of the `env` list (`ACCEPT_EULA`, `MSSQL_PID`, `MSSQL_MEMORY_LIMIT_MB`, ...), so check
it first with `kubectl -n sqllab get statefulset sqlserver -o jsonpath='{.spec.template.spec.containers[0].env[*].name}'`.
This restarts the Pod.

I tried to express profiles as Kustomize overlays, but an overlay directory nested under a base that is the repository
root creates a cycle ("candidate root contains visited root"). Making that work means moving the base into its own
directory, and then the `sql/` files fall outside its load restrictions. Left for later; the patch recipe is the stopgap.

## PVC size

`volumeClaimTemplates` cannot be edited on an existing StatefulSet. To grow the data volume edit the PVC itself (if the
StorageClass allows expansion) and leave the template alone.
