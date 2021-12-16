
DECLARE @datatype nvarchar(255) = '%VARCHAR%'
DECLARE @datavalue nvarchar(255) = '%Courtesy Credit%'

DECLARE @objectid int = -1;
DECLARE @colid int;
DECLARE @tablename sysname;
DECLARE @colname sysname;
DECLARE @sql nvarchar(4000);

WHILE (EXISTS (
	SELECT O.name
	FROM sys.columns C 
	INNER JOIN sys.objects O 
		ON O.object_id = C.object_id 
	INNER JOIN sys.schemas S
		ON S.schema_id = O.schema_id
	INNER JOIN sys.types T
		ON T.system_type_id = C.system_type_id
	WHERE O.type = 'U'
		AND T.name LIKE @datatype
		AND O.object_id > @objectid ))
BEGIN
	SET @colid = -1;
	
	SELECT TOP 1
		@objectid = O.object_id, 
		@tablename = '[' + S.name + '].[' + O.name + ']'
	FROM sys.columns C 
	INNER JOIN sys.objects O 
		ON O.object_id = C.object_id 
	INNER JOIN sys.schemas S
		ON S.schema_id = O.schema_id
	INNER JOIN sys.types T
		ON T.system_type_id = C.system_type_id
	WHERE O.type = 'U'
		AND T.name LIKE @datatype
		AND O.object_id > @objectid
	ORDER BY O.object_id

	

	WHILE (EXISTS (SELECT C.name
	FROM sys.columns C 
	INNER JOIN sys.types T
		ON T.system_type_id = C.system_type_id
	WHERE C.object_id = @objectid
		AND T.name LIKE @datatype
		AND C.column_id > @colid ))
	BEGIN
		SELECT TOP 1
			@colid = C.column_id,
			@colname = C.name
		FROM sys.columns C 
		INNER JOIN sys.types T
			ON T.system_type_id = C.system_type_id
		WHERE C.object_id = @objectid
			AND T.name LIKE @datatype
			AND C.column_id > @colid
		
		SET @sql = '

		IF (EXISTS (SELECT TOP 1 * FROM ' + @tablename + ' WHERE [' + @colname + '] LIKE @datavalue ))
		BEGIN
			SELECT TOP 1 ''' + @tablename + '.' + @colname + ''', *
			FROM ' + @tablename + '
			WHERE [' + @colname + '] LIKE @datavalue
		END
		'
		EXEC sp_executesql @sql, N'@datavalue nvarchar(255)', @datavalue = @datavalue

	END


END


--LAWSSL  '%Courtesy Credit%'

--SELECT * FROM TimeEnt
--SELECT * FROM arwo
--where ARWriteOffExplanation LIKE '%courtesy%'
----SELECT * FROM actcode
--SELECT * FROM Diary
--SELECT * FROM PCLAW.CreditsTable
--where ARWriteOffExplanation LIKE '%courtesy%'
--SELECT * FROM GBAlloc