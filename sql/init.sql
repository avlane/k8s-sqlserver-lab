-- Creates the lab database and a sample table. Safe to run more than once.
SET NOCOUNT ON;
GO
IF DB_ID(N'LabDb') IS NULL
BEGIN
    CREATE DATABASE LabDb;
END
GO
USE LabDb;
GO
IF OBJECT_ID(N'dbo.Orders', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Orders
    (
        OrderId      int IDENTITY(1, 1) NOT NULL CONSTRAINT PK_Orders PRIMARY KEY,
        CustomerName nvarchar(100)      NOT NULL,
        Amount       decimal(10, 2)     NOT NULL,
        CreatedAtUtc datetime2(0)       NOT NULL CONSTRAINT DF_Orders_CreatedAtUtc DEFAULT SYSUTCDATETIME()
    );

    INSERT dbo.Orders (CustomerName, Amount)
    SELECT CONCAT(N'Customer ', n.n), CONVERT(decimal(10, 2), n.n * 1.25)
    FROM (
        SELECT TOP (1000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
        FROM sys.all_objects AS a CROSS JOIN sys.all_objects AS b
    ) AS n;
END
GO
SELECT COUNT(*) AS OrderRows FROM dbo.Orders;
GO
