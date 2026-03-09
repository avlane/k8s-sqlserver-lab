-- Creates a login for applications with read/write access to LabDb only.
-- Usage: sqlcmd ... -i sql/create-app-login.sql -v APP_PASSWORD="a-strong-password"
SET NOCOUNT ON;
GO
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'lab_app')
BEGIN
    CREATE LOGIN lab_app WITH PASSWORD = N'$(APP_PASSWORD)', CHECK_POLICY = ON, CHECK_EXPIRATION = OFF;
END
GO
USE LabDb;
GO
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'lab_app')
BEGIN
    CREATE USER lab_app FOR LOGIN lab_app;
END
ALTER ROLE db_datareader ADD MEMBER lab_app;
ALTER ROLE db_datawriter ADD MEMBER lab_app;
GO
