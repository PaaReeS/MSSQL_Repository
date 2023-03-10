/****** Object:  StoredProcedure [dbo].[proc_dbsize]    Script Date: 15/10/2019 15:23:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE procedure [dbo].[proc_dbsize] with encryption
as
BEGIN
	SET NOCOUNT ON;
	IF OBJECT_ID('tempdb.#temptab') is not null
	DROP TABLE #temptab;
	
	CREATE TABLE #temptab(
	DATABASE_NAME sysname
	, FILE_SIZE decimal(12, 2)
	, SPACE_USED decimal(12, 2)
	, FILE_MAX_SIZE decimal(12, 2)
	, TYPE nvarchar(3)
	);
	DECLARE @v_db_name nvarchar(50)
	DECLARE @SqlStatement nvarchar(max)
	DECLARE c_databases CURSOR LOCAL FAST_FORWARD FOR
	SELECT name  FROM sys.databases;
	OPEN c_databases;
	WHILE 1=1
	BEGIN
		FETCH NEXT FROM c_databases INTO @v_db_name;
		IF @@FETCH_STATUS = -1 BREAK;
		SET @SqlStatement = N'USE '
		+ QUOTENAME(@v_db_name)
		+ CHAR(13)+ CHAR(10)
		+ N'INSERT INTO #temptab
		SELECT
		DB_NAME()
		, CONVERT(DECIMAL(12,2), ROUND(f.size/128.00,2))
		, CONVERT(DECIMAL(12,2), ROUND(fileproperty(f.name, ''SpaceUsed'')/128.00,2))
		, CONVERT(DECIMAL(12,2), ROUND(f.max_size/128.00,2))
		, case
			when type = 1 then ''LOG''
			when type = 0 then ''ROW''
		  end 
		FROM sys.database_files f'
		EXEC (@SqlStatement)
	END;
	CLOSE c_databases;
	DEALLOCATE c_databases;
	SET NOCOUNT OFF;
	SELECT
	cast(DB_ID(database_name) as nvarchar(3)) as DB_ID
	, cast(database_name  as nvarchar(50)) as DB_Name
	, cast(z.type as nvarchar(3)) as Type
	, cast(z.space_used as nvarchar(15)) as Space_used
	, cast(z.file_size as nvarchar(15)) as File_size
	, cast(z.file_max_size as nvarchar(15))  as file_max_size	
	, cast(cast((file_max_size - space_used) / file_max_size * 100.00 as decimal(12, 2)) as nvarchar(15)) AS percentage_free 
	FROM(
		SELECT
		database_name
		, type
		, SUM(file_size) as file_size
		, SUM(file_max_size) AS file_max_size
		, SUM(space_used) AS space_used
		FROM #temptab
		WHERE file_max_size > 0
		GROUP BY database_name, type
	) AS z
	ORDER BY DB_ID(database_name), Type DESC;
		
	DROP TABLE #temptab;
END




GO
