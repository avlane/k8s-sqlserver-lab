# Availability group sketches

These files exist so the read-scale discussion in
`docs/read-scale-ag.md` has concrete statements to criticise. They are not part of the kustomization and are not mounted into any Pod.
They assume two replicas named `sqlserver-0` and `sqlserver-1`, which the current StatefulSet (one replica, no port 5022,
no `MSSQL_ENABLE_HADR`) does not provide.
