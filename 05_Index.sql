--Index

/*
	Table Scan: Durchsuche die gesamte Tabelle (langsam)
	Index Scan: Durchsuche bestimmte der Teile der Tabelle (besser)
	Index Seek: Gehe in einen Index gezielt zu den Daten hin (am besten)

	Clustered Index:
	Normaler Index, welcher sich immer selbst sortiert
	Bei INSERT/UPDATE werden die Daten herumgeschoben
	Kann nur einmal existieren pro Tabelle
	-> Kostet Performance
	Standardm‰ﬂig mit PK erstellt

	Non-Clustered Index:
	Standardindex
	Zwei Komponenten: Schl¸sselspalten, inkludierten Spalten
	Anhand der Komponenten entscheidet die DB ob der Index verwendet wird
	Verh‰lt sich wie mehrere extra Tabellen, welche miteinander verkettet sind
*/

--SELECT *
--INTO M005_Index
--FROM M004_Kompression

USE Demo2;

SET STATISTICS time, io ON

--Table Scan
SELECT * FROM M005_Index

SELECT *
FROM M005_Index
WHERE OrderID >= 11000
--Table Scan
--Cost: 42, logische Lesevorg‰nge: 56642, CPU-Zeit = 1438 ms, verstrichene Zeit = 2883 ms

--Neuer Index: NCIX_OrderID
SELECT *
FROM M005_Index
WHERE OrderID >= 11000
--Index Seek
--Cost 4.3, logische Lesevorg‰nge: 5790, CPU-Zeit = 484 ms, verstrichene Zeit = 3001 ms

--Indizes anschauen
SELECT OBJECT_NAME(object_id), index_level, page_count
FROM sys.dm_db_index_physical_stats(DB_ID(), 0, -1, 0, 'DETAILED')
WHERE OBJECT_NAME(object_id) = 'M005_Index'

--Auf bestimmte (h‰ufige) Abfragen Indizes aufbauen
SELECT CompanyName, ContactName, ProductName, Quantity * UnitPrice
FROM M005_Index
WHERE ProductName = 'Chocolade'
--Table Scan
--Cost: 42, logische Lesevorg‰nge: 56642, CPU-Zeit = 327 ms, verstrichene Zeit = 226 ms

--Neuer Index: NCIX_ProductName
SELECT CompanyName, ContactName, ProductName, Quantity * UnitPrice
FROM M005_Index
WHERE ProductName = 'Chocolade'
--Index Seek
--Cost: 0.04, logische Lesevorg‰nge: 49, CPU-Zeit = 0 ms, verstrichene Zeit = 150 ms

--Hier wird auch NCIX_ProductName durchgegangen
--Hier fehlt die ContactName Spalte
SELECT CompanyName, ProductName, Quantity * UnitPrice
FROM M005_Index
WHERE ProductName = 'Chocolade'

--Hier wird NCIX_ProductName teils durchgegangen
--Alle Included Columns werden geholt + ein Lookup auf die fehlenden Daten die im Index nicht enthalten sind
SELECT CompanyName, ContactName, ProductName, Quantity * UnitPrice, Freight
FROM M005_Index
WHERE ProductName = 'Chocolade'
--Cost: 10, logische Lesevorg‰nge: 3121, CPU-Zeit = 31 ms, verstrichene Zeit = 194 ms

--Neuer Index: NCIX_Freight
SELECT CompanyName, ContactName, Phone, ProductName, Quantity * UnitPrice, Freight, FirstName, LastName
FROM M005_Index
WHERE Freight > 50
--Table Scan
--Cost 43, logische Lesevorg‰nge: 56642, CPU-Zeit = 1500 ms, verstrichene Zeit = 7268 ms

--Ohne Extra Spalten
SELECT CompanyName, ContactName, ProductName, Quantity * UnitPrice, Freight
FROM M005_Index
WHERE Freight > 50
--Index Seek
--Cost: 7.8, logische Lesevorg‰nge: 9609, CPU-Zeit = 1094 ms, verstrichene Zeit = 7903 ms

SELECT CompanyName, ContactName, ProductName, Quantity * UnitPrice, Freight
FROM M005_Index
--Ohne WHERE: Index Scan
--Cost: 15, logische Lesevorg‰nge: 18761, CPU-Zeit = 1359 ms, verstrichene Zeit = 11112 ms

SELECT CompanyName, ContactName, Phone, UnitPrice * Quantity
FROM M005_Index
WHERE UnitPrice > 20

--------------------------------------------------------------------

--Indizierte Sicht
--View mit Index
--Benˆtigt SCHEMABINDING
--WITH SCHEMABINDING: Solange die View existiert, kann die Tabellenstruktur nicht ver‰ndert werden
ALTER TABLE M005_Index ADD id int identity
GO

DROP VIEW Adressen

CREATE VIEW Adressen WITH SCHEMABINDING
AS
SELECT id, CompanyName, Address, City, Region, PostalCode, Country
FROM dbo.M005_Index

--Clustered Index Scan
SELECT * FROM Adressen;

--Clustered Index Scan
--Abfrage auf die Tabelle verwendet hier den Index der View
SELECT id, CompanyName, Address, City, Region, PostalCode, Country
FROM dbo.M005_Index

--Clustered Index Insert
INSERT INTO M005_Index (id,  CompanyName, Address, City, Region, PostalCode, Country)
VALUES (1234567, 'PPEDV', 'Eine Straﬂe', 'Irgendwo', NULL, NULL, NULL)

--Clustered Index Delete
DELETE FROM M005_Index
WHERE id = 1234567
  and CompanyName = 'PPEDV'
  and Address = 'Eine Straﬂe'
  and City = 'Irgendwo'
  and Region IS NULL
  and PostalCode IS NULL
  and Country IS NULL

--------------------------------------------------------------------

--Columnstore Index
--Nimmt eine oder mehrere Spalten und entnimmt die Werte und baut eine Tabelle daraus
--Eine Spalte mit 10Mio. DS
--Eine Spalte im CS Index hat 2^20 Platz (1048576)
--| S1 | S2 | S3 | S4 | S5 | S6 | S7 | S8 | S9 |
--Pro Spalte: | W1, W2, W3, ...|
--Alle Werte die keine Spalte komplett ausf¸llen kˆnnen, werden in einem separaten Deltastore gespeichert

SELECT *
INTO M005_CS
FROM M005_Index

--INSERT INTO M005_CS
--SELECT * FROM M005_CS
--GO 5

SELECT OrderID FROM M005_CS
--logische Lesevorg‰nge: 1827180, CPU-Zeit = 24156 ms, verstrichene Zeit = 212157 ms

SELECT OrderID FROM KU
--logische Lesevorg‰nge: 0, CPU-Zeit = 5188 ms, verstrichene Zeit = 543988 ms
--logische LOB-Lesevorg‰nge: 16774, physische LOB-Lesevorg‰nge: 13, LOB-Read-Ahead-Lesevorg‰nge: 50449

--ColumnStore Indizes ansehen
SELECT OBJECT_NAME(object_id), *
FROM sys.dm_db_column_store_row_group_physical_stats

--------------------------------------------------------------------

--Indizes warten
--‹ber Zeit werden die Indizes unorganisiert
---> Reorganize oder Rebuild
--Total Fragmentation: Wie verstreut der Index ist
--Sollte regelm‰ﬂig gemacht werden
--Bei kleinen Indizes: Reorganize, bei groﬂen Indizes: direkt Rebuild