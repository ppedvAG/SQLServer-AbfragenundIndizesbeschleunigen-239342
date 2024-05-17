CREATE DATABASE UebungFinale;

USE UebungFinale;

SELECT * INTO Suppliers FROM Northwind.dbo.Suppliers;

SELECT * INTO Products FROM Northwind.dbo.Products;

SELECT * INTO Orders FROM Northwind.dbo.Orders;

SELECT * INTO Customers FROM Northwind.dbo.Customers;

SELECT * INTO [Order Details] FROM Northwind.dbo.[Order Details];

----------------------------------------------------------------------------------------------------

INSERT INTO Suppliers
SELECT [CompanyName]
           ,[ContactName]
           ,[ContactTitle]
           ,[Address]
           ,[City]
           ,[Region]
           ,[PostalCode]
           ,[Country]
           ,[Phone]
           ,[Fax]
           ,[HomePage] FROM Suppliers
GO 8

INSERT INTO Products
SELECT 
[ProductName]
           ,[SupplierID]
           ,[CategoryID]
           ,[QuantityPerUnit]
           ,[UnitPrice]
           ,[UnitsInStock]
           ,[UnitsOnOrder]
           ,[ReorderLevel]
           ,[Discontinued] FROM Products
GO 8

INSERT INTO Orders
SELECT [CustomerID]
           ,[EmployeeID]
           ,[OrderDate]
           ,[RequiredDate]
           ,[ShippedDate]
           ,[ShipVia]
           ,[Freight]
           ,[ShipName]
           ,[ShipAddress]
           ,[ShipCity]
           ,[ShipRegion]
           ,[ShipPostalCode]
           ,[ShipCountry] FROM Orders
GO 8

INSERT INTO Customers
SELECT [CustomerID]
           ,[CompanyName]
           ,[ContactName]
           ,[ContactTitle]
           ,[Address]
           ,[City]
           ,[Region]
           ,[PostalCode]
           ,[Country]
           ,[Phone]
           ,[Fax] FROM Customers
GO 8

INSERT INTO [Order Details]
SELECT [OrderID]
           ,[ProductID]
           ,[UnitPrice]
           ,[Quantity]
           ,[Discount] FROM [Order Details]
GO 8