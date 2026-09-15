-- Run on each replica. Replace the passwords.
-- Creates a certificate and a database mirroring endpoint that authenticates with it.
CREATE MASTER KEY ENCRYPTION BY PASSWORD = N'$(MASTER_KEY_PASSWORD)';
GO
CREATE CERTIFICATE ag_endpoint_cert WITH SUBJECT = N'availability group endpoint';
GO
BACKUP CERTIFICATE ag_endpoint_cert
    TO FILE = N'/var/opt/mssql/data/ag_endpoint_cert.cer';
GO
CREATE ENDPOINT [Hadr_endpoint]
    STATE = STARTED
    AS TCP (LISTENER_PORT = 5022)
    FOR DATABASE_MIRRORING (ROLE = ALL, AUTHENTICATION = CERTIFICATE ag_endpoint_cert, ENCRYPTION = REQUIRED ALGORITHM AES);
GO
-- Still to do by hand: copy the .cer files between the replicas, then on each replica
-- CREATE LOGIN for the other one, CREATE USER FROM LOGIN, CREATE CERTIFICATE ... FROM FILE,
-- and GRANT CONNECT ON ENDPOINT::Hadr_endpoint TO that login.
