# k8s-sqlserver-lab

A learning lab for running SQL Server in a container on Kubernetes: a StatefulSet with
a PersistentVolumeClaim, a Secret for the SA password, a Service, probes that use
`sqlcmd`, a backup CronJob and a restore-test Job. The point is to understand the moving parts and
write down the pitfalls, not to provide a production recipe.

## Layout

(filled in as the lab grows)
