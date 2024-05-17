/*
	Normalerweise:
	1. Jede Zelle sollte einen Wert haben
	2. Jeder Datensatz sollte einen Primärschlüssel haben
	3. Keine Beziehungen zwischen nicht-Schlüssel Spalten

	Redundanz verringern (Daten nicht doppelt speichern)
	- Weniger Speicherbedarf
	- Keine Inkonsistenz -> Doppelte können nicht unterschiedlich sein
	- Beziehungen zwischen Tabellen
	- Große Tabellen in kleinere Tabellen aufteilen

	Beziehungen:
	- 100 Mio. Orders
	- 1 Mio. Adressen
	Orders <-> Beziehung <-> Adressen
*/

USE NorthwindTest;
-- Große Tabellen in kleinere Tabellen aufteilen
SELECT ShipName, ShipAddress, ShipCity, ShipRegion, ShipPostalCode, ShipCountry, COUNT(*)
FROM Orders
GROUP BY ShipName, ShipAddress, ShipCity, ShipRegion, ShipPostalCode, ShipCountry

CREATE TABLE Lieferadressen
(
	AddressID int identity primary key,
	ShipName nvarchar(40),
	ShipAddress nvarchar(60),
	[ShipCity] nvarchar(15),
	[ShipRegion] nvarchar(15),
	[ShipPostalCode] nvarchar(10),
	[ShipCountry] nvarchar(15)
);

INSERT INTO Lieferadressen
SELECT ShipName, ShipAddress, ShipCity, ShipRegion, ShipPostalCode, ShipCountry
FROM Orders
GROUP BY ShipName, ShipAddress, ShipCity, ShipRegion, ShipPostalCode, ShipCountry

ALTER TABLE Orders DROP COLUMN ShipName
ALTER TABLE Orders DROP COLUMN ShipAddress
ALTER TABLE Orders DROP COLUMN ShipCity
ALTER TABLE Orders DROP COLUMN ShipRegion
ALTER TABLE Orders DROP COLUMN ShipPostalCode
ALTER TABLE Orders DROP COLUMN ShipCountry

ALTER TABLE Orders ADD AddressID int

ALTER TABLE Orders
ADD CONSTRAINT FK_Orders_Lieferadressen
FOREIGN KEY (AddressID)
REFERENCES Lieferadressen(AddressID)

------------------------------------------------------------------------------------

/*
	Seite:
	8192B (8KB) Größe
	8060B für tatsächliche Daten
	132B für Management Daten

	Seiten werden immer 1:1 gelesen

	Max. 700DS Seite
	Datensätze müssen komplett auf eine Seite passen
	Leerer Raum darf existieren, sollte aber minimiert werden
*/

--dbcc: Database Console Commands
--showcontig: Zeigt Seiteninformationen über ein Datenbankobjekt
dbcc showcontig('Orders')

CREATE DATABASE Demo2;

USE Demo2;

--Absichtlich ineffiziente Tabelle
CREATE TABLE M001_Test1
(
	id int identity,
	test char(4100)
);

INSERT INTO M001_Test1
VALUES('XYZ')
GO 20000

dbcc showcontig('M001_Test1')

CREATE TABLE M001_Test2
(
	id int identity,
	test varchar(4100)
);

INSERT INTO M001_Test2
VALUES('XYZ')
GO 20000

--700DS Limit getroffen
dbcc showcontig('M001_Test2')

CREATE TABLE M001_Test3
(
	id int identity,
	test varchar(MAX)
);

INSERT INTO M001_Test3
VALUES('XYZ')
GO 20000

--700DS Limit getroffen
dbcc showcontig('M001_Test3')

CREATE TABLE M001_Test4
(
	id int identity,
	test nvarchar(MAX)
);

INSERT INTO M001_Test4
VALUES('XYZ')
GO 20000

dbcc showcontig('M001_Test4')

------------------------------------------------------------------------------------

--Statistiken für Zeit und Lesevorgänge zu aktivieren/deaktivieren
SET STATISTICS time, io ON

SELECT * FROM NorthwindTest.dbo.Lieferadressen  --logische Lesevorgänge: 4, CPU-Zeit = 0 ms, verstrichene Zeit = 8 ms

--logische LOB-Lesevorgänge für sehr große Datensätze
INSERT INTO M001_Test4 VALUES (REPLICATE('a', 20000))

SELECT * FROM M001_Test4  --logische LOB-Lesevorgänge: 14

--sys.dm_db_index_physical_stats: Gibt einen Gesamtüberblick über die Seiten der Datenbank
USE NorthwindTest;

SELECT OBJECT_NAME(object_id), *
FROM sys.dm_db_index_physical_stats(DB_ID(), 0, -1, 0, 'DETAILED')

SELECT OBJECT_NAME(581577110); --Name anhand der ID holen

SELECT OBJECT_ID('Orders') --ID anhand des Namens holen

------------------------------------------------------------------------------------

--Northwind optimieren
--Customers Tabelle
dbcc showcontig('Customers')
--72% Füllgrad -> mittelmäßig (ab 70% OK, ab 80% Gut, ab 90% Sehr Gut)
--Spalten mit n Unicode -> Auf Datentypen achten
--nvarchar: 2B pro Zeichen, varchar: 1B pro Zeichen
--CustomerID, PostalCode werden nur ASCII-Zeichen enthalten
---> Weniger Seiten -> weniger Daten laden -> bessere Performance

SELECT * FROM INFORMATION_SCHEMA.TABLES;
SELECT * FROM INFORMATION_SCHEMA.COLUMNS; --Alle Spalten der Datenbank anzeigen -> Datentypen

--Datentypen
--varchar: 1B pro Zeichen
--nvarchar: 2B pro Zeichen
--(n)text: nicht verwenden, alternative (n)varchar

--Numerische Typen
--int: 4B, häufig für Spalten verwendet
--tinyint: 1B, smallint: 2B, bigint: 8B

--money: 8B, smallmoney: 4B

--float: 8B
--decimal: je nach größe unterschiedlicher Verbrauch

--Datumswerte
--Datetime: 8B
--Date: 3B
--Time: 3B-5B (HH:MM:SS: 3B | Ms, µs, Ns: 5B)

USE Demo2;

CREATE TABLE M001_TestFloat
(
	id int identity,
	zahl float
);

INSERT INTO M001_TestFloat
VALUES(2.2)
GO 20000

dbcc showcontig('M001_TestFloat')

CREATE TABLE M001_TestDecimal
(
	id int identity,
	zahl decimal(2, 1)
);

INSERT INTO M001_TestDecimal
SELECT 2.2 FROM M001_TestFloat;

dbcc showcontig('M001_TestDecimal')

--Schnellere Variante
BEGIN TRAN;
DECLARE @i int = 0
WHILE @i < 20000
BEGIN
	INSERT INTO M001_TestDecimal VALUES(2.2)
	SET @i += 1
END
COMMIT;

CREATE TABLE M001_TestFloat2
(
	id int identity,
	zahl float
);

GO

TRUNCATE TABLE M001_TestFloat2;

BEGIN TRAN;
DECLARE @i int = 0
WHILE @i < 20000
BEGIN
	INSERT INTO M001_TestFloat2 VALUES(123456789123456789.123456789123456789)
	SET @i += 1
END
COMMIT;

--Selbe Größe
dbcc showcontig('M001_TestFloat2')

CREATE TABLE M001_TestDecimal2
(
	id int identity,
	zahl decimal(36, 18)
);

GO

BEGIN TRAN;
DECLARE @i int = 0
WHILE @i < 20000
BEGIN
	INSERT INTO M001_TestDecimal2 VALUES(123456789123456789.123456789123456789)
	SET @i += 1
END
COMMIT;

--Selbe Größe
dbcc showcontig('M001_TestDecimal2')

print(DATALENGTH(CONVERT(FLOAT, 123456789.123456789))) --8B
print(DATALENGTH(CONVERT(FLOAT, 2.2))) --8B

print(DATALENGTH(CONVERT(DECIMAL(18, 9), 123456789.123456789)))  --9B
print(DATALENGTH(CONVERT(DECIMAL(18, 9), 2.2))) --5B
print(DATALENGTH(CONVERT(DECIMAL(2, 1), 2.2))) --5B