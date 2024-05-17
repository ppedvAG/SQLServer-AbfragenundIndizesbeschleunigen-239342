--Query Store
--Erstellt während des Normalbetriebs Statistiken zu Abfragen
--Speichern Abfragen, Zeiten, Verbrauch, ...

--Rechtsklick auf DB -> Properties -> Query Store -> Operation Mode -> RW
USE Demo2;

SELECT * FROM Northwind.dbo.Orders o
INNER JOIN M005_Index i
ON o.CustomerID = i.CustomerID and o.OrderID = i.OrderID and o.EmployeeID = i.EmployeeID