-- Run on the intended primary (sqlserver-0).
-- CLUSTER_TYPE = NONE: no cluster manager, no automatic failover; read scale only.
-- The database must be in FULL recovery with at least one full backup taken.
CREATE AVAILABILITY GROUP [ag_lab]
WITH (CLUSTER_TYPE = NONE)
FOR DATABASE [LabDb]
REPLICA ON
    N'sqlserver-0' WITH (
        ENDPOINT_URL = N'tcp://sqlserver-0.sqlserver-headless.sqllab.svc.cluster.local:5022',
        AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT, FAILOVER_MODE = MANUAL, SEEDING_MODE = AUTOMATIC,
        SECONDARY_ROLE (ALLOW_CONNECTIONS = ALL)),
    N'sqlserver-1' WITH (
        ENDPOINT_URL = N'tcp://sqlserver-1.sqlserver-headless.sqllab.svc.cluster.local:5022',
        AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT, FAILOVER_MODE = MANUAL, SEEDING_MODE = AUTOMATIC,
        SECONDARY_ROLE (ALLOW_CONNECTIONS = ALL));
GO
