--Kompression

--Daten verkleinern
---> Weniger Daten werden geladen, beim dekomprimieren wird CPU Leistung verwendet

--Zwei verschiedene Typen
--Row Compression: 50%
--Page Compression: 75%
--Page Compression enthält Row Compression

USE Northwind;
SELECT  Orders.OrderDate, Orders.RequiredDate, Orders.ShippedDate, Orders.Freight, Customers.CustomerID, Customers.CompanyName, Customers.ContactName, Customers.ContactTitle, Customers.Address, Customers.City, 
        Customers.Region, Customers.PostalCode, Customers.Country, Customers.Phone, Orders.OrderID, Employees.EmployeeID, Employees.LastName, Employees.FirstName, Employees.Title, [Order Details].UnitPrice, 
        [Order Details].Quantity, [Order Details].Discount, Products.ProductID, Products.ProductName, Products.UnitsInStock
INTO Demo2.dbo.M004_Kompression
FROM    [Order Details] INNER JOIN
        Products ON Products.ProductID = [Order Details].ProductID INNER JOIN
        Orders ON [Order Details].OrderID = Orders.OrderID INNER JOIN
        Employees ON Orders.EmployeeID = Employees.EmployeeID INNER JOIN
        Customers ON Orders.CustomerID = Customers.CustomerID

USE Demo2;

INSERT INTO M004_Kompression
SELECT * FROM M004_Kompression
GO 8

SELECT COUNT(*) FROM M004_Kompression

SET STATISTICS time, io ON

--Rechtsklick auf Tabelle -> Storage -> Manage Compression

--Ohne Compression: logische Lesevorgänge: 56564, CPU-Zeit = 2937 ms, verstrichene Zeit = 20383 ms, 43 OP-Cost
SELECT * FROM M004_Kompression

--Row Compression
--441MB -> 248MB: ~44%
--logische Lesevorgänge: 31680, CPU-Zeit = 4047 ms, verstrichene Zeit = 22221 ms, 24.6 OP-Cost
SELECT * FROM M004_Kompression

--Page Compression
--247MB -> 122MB: ~73%
--logische Lesevorgänge: 15417, CPU-Zeit = 6703 ms, verstrichene Zeit = 25730 ms, 12.6 OP-Cost
SELECT * FROM M004_Kompression

--Partitionen können auch komprimiert werden
SELECT OBJECT_NAME(object_id), * FROM sys.dm_db_index_physical_stats(DB_ID(), 0, -1, 0, 'DETAILED')
WHERE compressed_page_count != 0

--Alle Kompressionen ausgeben

SELECT t.name AS TableName, p.partition_number AS PartitionNumber, p.data_compression_desc AS Compression
FROM sys.partitions AS p
JOIN sys.tables AS t ON t.object_id = p.object_id