SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[proc_check_db_status] with encryption
AS
BEGIN
	set nocount on
	DECLARE @RES nvarchar(255)		
	SET @RES = 'OK'
	insert into t_check_db_status select name, 'Y',cast(getdate()as datetime),'Auto-added' from master.sys.databases where name not in (select db_name from t_check_db_status ) --and state = 0
	IF((select count(1) from msdb.dbo.suspect_pages)>0)
		begin
			insert into [t_his_suspect_pages_log] select getdate(),sp.database_id,d.name,sp.file_id,mf.name,sp.page_id,sp.event_type
			, case 
			when sp.event_type = 1 then N'823 or 824 Error'
			when sp.event_type = 2 then N'Bad Checksum'
			when sp.event_type = 3 then N'Torn Page'
			when sp.event_type = 4 then N'Restored'
			when sp.event_type = 5 then N'Repaired'
			when sp.event_type = 7 then N'Deallocated'
			else N'N/A'
			end as event_type_desc,sp.error_count,sp.last_update_date,null 
			from msdb.dbo.suspect_pages sp	
				join sys.databases d on sp.database_id=d.database_id
				join sys.master_files mf on (mf.database_id=d.database_id and sp.file_id=mf.file_id)
			set @RES='CRITICAL # Corruption #'
		end
	IF((select count(1) from master.sys.databases d join t_check_db_status db on d.name=db.db_name	where state not in (0,7,10) and db.active='Y' )>0)
	begin
		insert into t_check_db_status_log select d.name, d.state_desc, cast(getdate()as datetime) from master.sys.databases d join t_check_db_status db on d.name=db.db_name where state not in (0,7,10) and db.active='Y' order by 3,1 desc
		IF @RES='OK'
			set @RES='CRITICAL'
		select @RES=coalesce(@RES+' #', '') +d.name+'='+d.state_desc from master.sys.databases d join t_check_db_status db on d.name=db.db_name where state not in (0,7,10) and db.active='Y' order by d.database_id desc
	end
	IF((select count(*) from t_check_db_status db where db.db_name not in ( select d.name from master.sys.databases d))>0)
	begin
		insert into t_check_db_status_log select db.db_name, 'BORRADA',cast(getdate()as datetime) from t_check_db_status db where db.db_name not in ( select d.name from master.sys.databases d)
		IF @RES='OK' 
			set @RES='CRITICAL # BBDD BORRADAS #'
		select @RES=coalesce(@RES+' #', '') +   db.db_name from t_check_db_status db where db.db_name not in ( select d.name from master.sys.databases d)
	end
	select @RES
END
go

