-- Run on the secondary (sqlserver-1).
ALTER AVAILABILITY GROUP [ag_lab] JOIN WITH (CLUSTER_TYPE = NONE);
GO
ALTER AVAILABILITY GROUP [ag_lab] GRANT CREATE ANY DATABASE;
GO
-- Look at it from either replica:
-- SELECT * FROM sys.dm_hadr_availability_replica_states;
-- SELECT * FROM sys.dm_hadr_database_replica_states;
