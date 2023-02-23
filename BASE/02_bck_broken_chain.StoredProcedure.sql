create  procedure sp_bck_broken_chain with encryption
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @lsn numeric(25,0)
	DECLARE @database_name nvarchar(255)
	DECLARE @RES NVARCHAR(500)
	
	CREATE TABLE #temptab(
	database_name sysname
	, backup_finish_date datetime
	, database_backup_lsn numeric(25,0)
	, lsn_full numeric(25,0));

	SET @RES = 'OK'
	DECLARE db_cursor CURSOR FOR
	select name from sys.databases where database_id <> 2
	OPEN db_cursor;
	WHILE 1=1
	BEGIN
		FETCH NEXT FROM db_cursor INTO @database_name;
		IF @@FETCH_STATUS = -1 BREAK;
		/* Obtenemos el lsn del ultimo full */
		SET @lsn= (select top 1 b.checkpoint_lsn
		FROM msdb.dbo.backupmediafamily  f
			INNER JOIN msdb.dbo.backupset b
				ON f.media_set_id = b.media_set_id  
		WHERE  1=1
		and b.type='D'
		and b.database_name= @database_name
		and f.device_type <> 7
		order by b.backup_finish_date desc)

		/* Revisamos si existe algun backup con lsn superior */
		insert into #temptab
		select top 1 database_name,backup_finish_date,database_backup_lsn, @lsn
		FROM   msdb.dbo.backupset 
		WHERE  1=1
		/*and (CONVERT(datetime, backupset.backup_start_date, 102) >= GETDATE() - 2)  */
		and backupset.backup_start_date > GETDATE() - 2
		and database_name= @database_name
		and database_backup_lsn > @lsn
		order by backup_finish_date asc
	END
	CLOSE db_cursor;
	DEALLOCATE db_cursor;
	
	IF ((select count(1) from #temptab) >0)
	BEGIN	
		insert into t_check_broken_chain_log select getdate(),database_name,backup_finish_date,database_backup_lsn,lsn_full from #temptab
		set @RES='CRITICAL'
		select @RES=coalesce(@RES+' #', '') +database_name+' BROKEN' from #temptab
	END
	drop table #temptab
	select @RES;
	
END
GO