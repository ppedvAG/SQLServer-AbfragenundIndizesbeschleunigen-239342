/*
	Dateigruppen:
	Datenbank aufteilen auf mehrere Dateien, und verschiedene Datentr‰ger in weiterer Folge
	[PRIMARY]: Hauptgruppe, existert immer, enth‰lt standardm‰ﬂig alle Files

	Das Hauptfile hat die Endung .mdf
	Weitere Files haben die Endung .ndf
	Log Files haben die Endung .ldf
*/

USE Demo2;

/*
	Rechtsklick auf die DB -> Properties
	Filegroups
		- Add, Name vergeben
	Files
		- Add, Name, Filegroup, Autogrowth, Pfad, Dateiname
*/

CREATE TABLE M002_FG2
(
	id int identity,
	test char(4100)
);

INSERT INTO M002_FG2
VALUES ('XYZ')
GO 20000

--Wie verschiebe ich eine Tabelle auf eine andere Dateigruppe?
--Neu erstellen, Daten verschieben, Alte Tabelle lˆschen
CREATE TABLE M002_FG2_2
(
	id int,
	test char(4100)
) ON [AKTIV]

INSERT INTO M002_FG2_2
SELECT * FROM M002_FG2

--Identity hinzuf¸gen per Designer
--Tools -> Options -> Designer -> Prevent saving changes that require table re-creation -> Ausschalten

--Tabellenstruktur kopieren
SELECT TOP 0 *
INTO Test
FROM M002_FG2_2;

--Salamitaktik
--Groﬂe Tabellen in kleinere Tabellen aufteilen
--Bonus: mit Partitionierten Sicht auf die unterliegenden Zugreifen

CREATE TABLE M002_Umsatz
(
	datum date,
	umsatz float
);

BEGIN TRAN;
DECLARE @i int = 0;
WHILE @i < 100000
BEGIN
	INSERT INTO M002_Umsatz VALUES
	(DATEADD(DAY, FLOOR(RAND()*1095), '20210101'), RAND() * 1000);
	SET @i += 1;
END
COMMIT;

TRUNCATE TABLE M002_Umsatz;

SELECT * FROM M002_Umsatz ORDER BY datum DESC;

/*
	Pl‰ne:
	Zeigt den genauen Ablauf einer Abfrage + Details an
	Aktivieren mit dem Button "Include Actual Execution Plan"

	Wichtige Werte:
	- Estimated Operator Cost: Prozentualer Anteil des Leistungsverbrauchs der Abfrage
	- Number of Rows Read: Anzahl Zeilen
*/

--2 Pfade
SELECT * FROM M002_Umsatz
UNION ALL
SELECT * FROM M002_Umsatz

SELECT * FROM M002_Umsatz WHERE YEAR(datum) = 2021 --Alle 100000 Zeilen mussten durchsucht werden

--------------------------------------------

CREATE TABLE M002_Umsatz2021
(
	datum date,
	umsatz float
);

INSERT INTO M002_Umsatz2021
SELECT * FROM M002_Umsatz WHERE YEAR(datum) = 2021

CREATE TABLE M002_Umsatz2022
(
	datum date,
	umsatz float
);

INSERT INTO M002_Umsatz2022
SELECT * FROM M002_Umsatz WHERE YEAR(datum) = 2022

CREATE TABLE M002_Umsatz2023
(
	datum date,
	umsatz float
);

INSERT INTO M002_Umsatz2023
SELECT * FROM M002_Umsatz WHERE YEAR(datum) = 2023

--------------------------------------------

--Indizierte Sicht
--View, welche auf nur die unterliegenden Tabellen greift, welche auch benˆtigt werden

ALTER TABLE M002_Umsatz2021 ADD CONSTRAINT UmsatzJahr2021 CHECK (YEAR(datum) = 2021)
ALTER TABLE M002_Umsatz2022 ADD CONSTRAINT UmsatzJahr2022 CHECK (YEAR(datum) = 2022)
ALTER TABLE M002_Umsatz2023 ADD CONSTRAINT UmsatzJahr2023 CHECK (YEAR(datum) = 2023)

CREATE VIEW UmsatzGesamt
AS
SELECT * FROM M002_Umsatz2021
UNION ALL
SELECT * FROM M002_Umsatz2022
UNION ALL
SELECT * FROM M002_Umsatz2023

SELECT *
FROM UmsatzGesamt
WHERE datum >= '20210101' and datum <= '20211231';