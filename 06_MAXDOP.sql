--MAXDOP
--Maximum Degree of Parallelism
--Steuerung der Anzahl Prozessorkerne pro Abfrage
--Parallelisierung passiert von alleine

--Kann auf drei verschiedenen Ebenen gesetzt werden
--Query > DB > Server

--Cost Threshold for Parallelism: Gibt die Kosten an die eine Abfrage haben muss, um parallelisiert zu werden
--Maximum Degree of Parallelism: Gibt die maximale Anzahl Prozessorkerne an, die eine Abfrage verwenden darf

--Verwendung: Priorisierung von Queries

SET STATISTICS time, io ON

SELECT Freight, FirstName, LastName
FROM M005_Index
WHERE Freight > (SELECT AVG(freight) FROM M005_Index)
--Diese Abfrage wird parallelisiert durch die Zwei schwarzen Pfeile in dem gelben Kreis

SELECT Freight, FirstName, LastName
FROM M005_Index
WHERE Freight > (SELECT AVG(freight) FROM M005_Index)
OPTION(MAXDOP 1)
--CPU-Zeit = 1500 ms, verstrichene Zeit = 3649 ms

SELECT Freight, FirstName, LastName
FROM M005_Index
WHERE Freight > (SELECT AVG(freight) FROM M005_Index)
OPTION(MAXDOP 2)
--CPU-Zeit = 1563 ms, verstrichene Zeit = 3541 ms

SELECT Freight, FirstName, LastName
FROM M005_Index
WHERE Freight > (SELECT AVG(freight) FROM M005_Index)
OPTION(MAXDOP 4)
--CPU-Zeit = 2030 ms, verstrichene Zeit = 3778 ms

SELECT Freight, FirstName, LastName
FROM M005_Index
WHERE Freight > (SELECT AVG(freight) FROM M005_Index)
OPTION(MAXDOP 8)
--CPU-Zeit = 1829 ms, verstrichene Zeit = 3783 ms