/*
	Partitionierung:
	Aufteilung in "mehrere" Tabellen
	Einzelne Tabelle bleibt bestehen, aber intern werden die Daten partitioniert
*/

--Anforderungen:
--Partitionsfunktion: Stellt die Bereiche dar (0-100, 101-200, 201-Ende)
--Partitionsschema: Weist die einzelnen Partitionen auf Dateigruppen zu

--0-100-200-Ende
CREATE PARTITION FUNCTION pf_Zahl(int) AS
RANGE LEFT FOR VALUES(100, 200)

DROP PARTITION SCHEME sch_ID;

--Für ein Partitionsschema muss immer eine extra Dateigruppe existieren
CREATE PARTITION SCHEME sch_ID AS
PARTITION pf_Zahl TO (P1, P2, P3)

ALTER DATABASE Demo2 ADD FILEGROUP P1

ALTER DATABASE Demo2
ADD FILE
(
	NAME = N'P1',
	FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\Demo2\P1.ndf',
	SIZE = 8192KB,
	FILEGROWTH = 65536KB
)
TO FILEGROUP P1

--

ALTER DATABASE Demo2 ADD FILEGROUP P2

ALTER DATABASE Demo2
ADD FILE
(
	NAME = N'P2',
	FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\Demo2\P2.ndf',
	SIZE = 8192KB,
	FILEGROWTH = 65536KB
)
TO FILEGROUP P2

--

ALTER DATABASE Demo2 ADD FILEGROUP P3

ALTER DATABASE Demo2
ADD FILE
(
	NAME = N'P3',
	FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\Demo2\P3.ndf',
	SIZE = 8192KB,
	FILEGROWTH = 65536KB
)
TO FILEGROUP P3

------------------------------------------------------

--Hier muss die Tabelle auf das Schema gelegt werden
CREATE TABLE M003_Test
(
	id int identity,
	zahl float
) ON sch_ID(id)

BEGIN TRAN;
DECLARE @i int = 0;
WHILE @i < 1000
BEGIN
	INSERT INTO M003_Test VALUES (RAND() * 1000);
	SET @i += 1;
END
COMMIT;

--Nichts besonderes zu sehen
SELECT * FROM M003_Test;

--Hier wird nur die unterste Partition durchsucht (100DS)
SELECT *
FROM M003_Test
WHERE id < 50

SET STATISTICS time, io ON

--Hier wird die oberste Partition durchsucht (800DS)
SELECT *
FROM M003_Test
WHERE id > 500

--Übersicht über Partition verschaffen
SELECT OBJECT_NAME(object_id), * FROM sys.dm_db_index_physical_stats(DB_ID(), 0, -1, 0, 'DETAILED')

SELECT $partition.pf_Zahl(50);
SELECT $partition.pf_Zahl(150);
SELECT $partition.pf_Zahl(250);

SELECT $partition.pf_Zahl(id), COUNT(*), AVG(zahl) FROM M003_Test
GROUP BY $partition.pf_Zahl(id)

SELECT * FROM sys.filegroups
SELECT * FROM sys.allocation_units

------------------------------------------------------

SELECT OBJECT_NAME(ips.object_id), name, ips.partition_number FROM sys.filegroups fg
JOIN sys.allocation_units au ON fg.data_space_id = au.data_space_id
JOIN sys.partitions p ON p.hobt_id = au.container_id
JOIN sys.dm_db_index_physical_stats(DB_ID(), 0, -1, 0, 'DETAILED') ips ON ips.hobt_id = p.hobt_id

--Pro Datensatz die Partition + Filegroup anhängen
SELECT * FROM M003_Test t
JOIN 
(
	SELECT name, ips.partition_number
	FROM sys.filegroups fg  --Name
	
	JOIN sys.allocation_units au
	ON fg.data_space_id = au.data_space_id

	JOIN sys.dm_db_index_physical_stats(DB_ID(), 0, -1, 0, 'DETAILED') ips
	ON ips.hobt_id = au.container_id

	WHERE OBJECT_NAME(ips.object_id) = 'M003_Test'
) x
ON $partition.pf_Zahl(t.id) = x.partition_number

--Daten per Partition verschieben
DROP TABLE M003_Archiv

CREATE TABLE M003_Archiv
(
	id int identity,
	zahl float
) ON [P1]

ALTER TABLE M003_Test
SWITCH PARTITION(1) TO M003_Archiv; --Funktioniert nicht wenn die Archiv Tabelle Inhalte hat

--Per Hand
SELECT TOP 0 *
INTO M003_Archiv2
FROM M003_Test

SET IDENTITY_INSERT M003_Archiv2 ON

INSERT INTO M003_Archiv2 (id, zahl)
SELECT * FROM M003_Test
WHERE $partition.pf_Zahl(id) = 2

BEGIN TRAN;
DELETE FROM M003_Archiv2
WHERE $partition.pf_Zahl(id) = 2
COMMIT;

SET IDENTITY_INSERT M003_Archiv2 OFF

GO

CREATE PROC moveData(@partNumber int)
AS
SET IDENTITY_INSERT M003_Archiv2 ON

INSERT INTO M003_Archiv2 (id, zahl)
SELECT * FROM M003_Test
WHERE $partition.pf_Zahl(id) = @partNumber

BEGIN TRAN;
DELETE FROM M003_Test
WHERE $partition.pf_Zahl(id) = @partNumber
COMMIT;

SET IDENTITY_INSERT M003_Archiv2 OFF

EXEC moveData 2

------------------------------------

--Procedure für neue Partitionen (z.B. einmal pro Jahr)
GO
DROP PROC newPartition

GO
CREATE PROC newPartition(@fgName varchar(15), @newRange int)
AS
BEGIN
	DECLARE @path varchar(255) = CONCAT(N'''C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\Demo2\', @fgName, '.ndf''')
	
	DECLARE @sql varchar(MAX) = CONCAT('
		ALTER DATABASE Demo2 ADD FILEGROUP ', @fgName, ';
		ALTER DATABASE Demo2 ADD FILE
		(
			NAME = ', @fgName, ',
			FILENAME = ', @path, ',
			SIZE = 8192KB,
			FILEGROWTH = 65536KB
		)
		TO FILEGROUP ', @fgName, ';

		ALTER PARTITION SCHEME sch_IDNEXT USED ', @fgName, ';

		ALTER PARTITION FUNCTION pf_Zahl()SPLIT RANGE (', @newRange, ')');
	EXEC (@sql)
END

EXEC newPartition 'P4', 300

INSERT INTO M003_Test VALUES (123)

--Eine Tabelle in X-große Schritte aufteilen
create partition function pf_test(int) as
range left for values(5000, 10000, 15000, 20000)

select * from M001_Test1
where $partition.pf_test(id) = 1