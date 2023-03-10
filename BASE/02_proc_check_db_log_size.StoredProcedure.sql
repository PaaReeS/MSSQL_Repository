SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[proc_check_db_log_size] with encryption
AS
BEGIN
	CREATE TABLE #temptab(
	DATABASE_NAME sysname
	, SPACE_USED decimal(12, 2)
	, FILE_MAX_SIZE decimal(12, 2)
	);
	
	DECLARE @DB_ID int 	
	DECLARE @date datetime 
	DECLARE @database_name nvarchar(100) 
	DECLARE @critic nvarchar (10) 	
	DECLARE @file_size decimal(12, 2)
	DECLARE @file_max_size decimal(12, 2)
	DECLARE @percentage_free DECIMAL(12,2)
	DECLARE @res NVARCHAR(500)
	DECLARE @SqlStatement nvarchar(max)
	DECLARE @v_w NUMERIC (12,2)
	DECLARE @v_c NUMERIC (12,2)
	
	declare @sqlcursorversion nvarchar(max)
		
	SET @v_w = (SELECT CAST(valor AS NUMERIC (12,2)) FROM [t_parametros] WHERE keyid = 41)
	SET @v_c = (SELECT CAST(valor2 AS NUMERIC (12,2)) FROM [t_parametros] WHERE keyid = 41)
	SET @RES = 'OK'
	if (cast(@@version as varchar (25)) = 'Microsoft SQL Server 2008')
	begin
	set @sqlcursorversion='DECLARE db_cursor CURSOR FOR
	SELECT name  FROM sys.databases WHERE database_id NOT IN (SELECT database_id FROM sys.master_files WHERE max_size = -1 AND type = 1) and state = 0;'
	end
	else
	if (cast(@@version as varchar (25)) = 'Microsoft SQL Server 2012')
	begin
	set @sqlcursorversion='DECLARE db_cursor CURSOR FOR
	SELECT name  FROM sys.databases WHERE database_id NOT IN (SELECT database_id FROM sys.master_files WHERE max_size = -1 AND type = 1) and state = 0;'
	end
	else
	begin
	set @sqlcursorversion='DECLARE db_cursor CURSOR FOR
	SELECT sd.name  FROM sys.databases sd left outer join sys.dm_hadr_database_replica_states  as hdrs on hdrs.database_id = sd.database_id   WHERE sd.database_id NOT IN (SELECT database_id FROM sys.master_files WHERE max_size = -1 AND type = 1) and sd.state = 0 and coalesce(hdrs.is_primary_replica,''1'') =''1'';'
	end
	
	exec sp_executesql @sqlcursorversion
	
	OPEN db_cursor;
	WHILE 1=1
	BEGIN
		FETCH NEXT FROM db_cursor INTO @Database_Name;
		IF @@FETCH_STATUS = -1 BREAK;
		SET @SqlStatement = N'USE '
		+ QUOTENAME(@Database_Name)
		+ CHAR(13)+ CHAR(10)
		+ N'INSERT INTO #temptab
		SELECT
		DB_NAME()
		, CONVERT(DECIMAL(12,2), ROUND(fileproperty(f.name, ''SpaceUsed'')/128.00,2))
		, CONVERT(DECIMAL(12,2), ROUND(f.max_size/128.00,2))
		FROM sys.database_files f
		WHERE f.type = 1;';
		EXEC (@SqlStatement)
	END;
	CLOSE db_cursor;
	DEALLOCATE db_cursor;	
	
	DECLARE z_cursor CURSOR LOCAL FORWARD_ONLY STATIC FOR
	SELECT
	DB_ID(database_name)
	, database_name
	, z.space_used
	, z.file_max_size
	, z.percentage_free 
	, case when percentage_free < @v_c then 'CRITICAL#' else 'WARNING#' end AS critic
	--, IIF(percentage_free < @v_c, 'CRITICAL#', 'WARNING#') AS critic
	, sysdatetime()
	FROM(
		SELECT
		database_name
		, SUM(file_max_size) AS file_max_size
		, SUM(space_used) AS space_used
		, (SUM(file_max_size) - SUM(space_used)) / SUM(file_max_size) * 100.00 AS percentage_free
		FROM #temptab
		GROUP BY database_name
	) AS z
	WHERE percentage_free <= @v_w
	ORDER BY percentage_free DESC;
	
	OPEN z_cursor;
	IF CURSOR_STATUS('local', 'z_cursor') = 1 AND @@CURSOR_ROWS > 0
	BEGIN
		SET @RES = ''
		WHILE 1=1
		BEGIN
			FETCH NEXT FROM z_cursor INTO @DB_ID, @database_name, @file_size, @file_max_size, @percentage_free, @critic, @date
			IF @@FETCH_STATUS = -1 BREAK;
			
			INSERT INTO  t_check_db_size_log 
			SELECT @DB_ID, 'LOG', @database_name, @file_size, @file_max_size, @percentage_free, @critic, @date;
						
			SET @RES = @RES + @database_name + ' ' + CAST(@percentage_free AS NVARCHAR(6))+'%. '
		END
		SET @RES = @critic + @RES
	END;
	CLOSE z_cursor;
	DEALLOCATE z_cursor;	
	
	SELECT @res;	
END
