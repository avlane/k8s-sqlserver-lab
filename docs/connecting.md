# Connecting

## Port-forward or the Service

Inside the cluster use `sqlserver.sqllab.svc.cluster.local,1433` (or just `sqlserver` from the same namespace).
From a workstation: `kubectl -n sqllab port-forward service/sqlserver 1433:1433` and connect to `localhost,1433`.
The comma, not a colon, separates host and port in SQL Server connection strings and `sqlcmd -S`.

## Encryption

Current drivers (ODBC Driver 18, `mssql-tools18`, recent .NET and JDBC drivers) encrypt by default. The container generates a
self-signed certificate, so the client fails with a certificate-chain error unless you:

- pass `-C` to `sqlcmd` or `TrustServerCertificate=yes` in a connection string (fine for a lab, it disables the check that stops a man in the middle), or
- give SQL Server a certificate from a CA the client trusts (the right answer for anything real: mount a certificate and key from a Secret and configure them in `mssql.conf`).

Example connection strings:

    Server=localhost,1433;Database=LabDb;User Id=lab_app;Password=...;Encrypt=True;TrustServerCertificate=True
    Driver={ODBC Driver 18 for SQL Server};Server=localhost,1433;Database=LabDb;UID=lab_app;PWD=...;TrustServerCertificate=yes

## Which name does the client see?

A StatefulSet Pod keeps its name, so `sqlserver-0.sqlserver-headless` is stable. The `sqlserver` Service load-balances to ready Pods,
which with one replica is the same thing, but is the name applications should use so that adding a replica later does not change their configuration.
