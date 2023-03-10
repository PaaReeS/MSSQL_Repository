/****** Object:  StoredProcedure [dbo].[proc_check_event]    Script Date: 15/10/2019 15:23:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[proc_check_db_file_size] with encryption
AS
BEGIN
set nocount on
	DECLARE @RES NVARCHAR(MAX)
	DECLARE @db_size TABLE (db_size NVARCHAR(MAX))
	DECLARE @db_log_size TABLE (db_log_size NVARCHAR(MAX))
	--Si se añaden mas check, añadir variables como las superiores por check
	DECLARE @temptab TABLE (RES NVARCHAR(MAX)
							, LVL NVARCHAR(1))
	
	INSERT INTO @db_size
	EXEC [proc_check_db_data_size];
	
	INSERT INTO @db_log_size
	EXEC [proc_check_db_log_size];
	
	WITH t (RES,lvl)
	AS (
	SELECT db_size, CASE LEFT(db_size,1) WHEN 'C' THEN '1' WHEN 'W' THEN '2' WHEN 'O' THEN '3' END FROM @db_size
	UNION ALL --Añadir select con cada nuevo check añadido
	SELECT db_log_size, CASE LEFT(db_log_size, 1) WHEN 'C' THEN '1' WHEN 'W' THEN '2' WHEN 'O' THEN '3' END FROM @db_log_size
	)
	INSERT INTO @temptab
	SELECT * FROM t;
	
	IF (SELECT MIN(lvl) FROM @temptab) = '3' 
		SET @RES='OK'
	ELSE
	BEGIN
		SET @RES=''
		DECLARE @v_RES NVARCHAR(MAX)
		DECLARE c_level CURSOR FOR SELECT RES FROM @temptab where lvl <> '3' order by lvl ASC;
		OPEN c_level;
		WHILE 1=1
		BEGIN
			FETCH NEXT FROM c_level INTO @v_RES;
			IF @@FETCH_STATUS = -1 BREAK;
		SET @RES=@RES + ' ' + @v_RES
		END
		CLOSE c_level;
		DEALLOCATE c_level;
	END
	
	SELECT @RES;

END
GO
