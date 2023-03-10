/****** Object:  StoredProcedure [dbo].[proc_check_rdto]    Script Date: 15/10/2019 15:23:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create PROCEDURE [dbo].[proc_check_rdto]  with encryption
AS
BEGIN
	set nocount on
	
	Declare @count_prc_c int
	Declare @res nvarchar(255)
	Declare @v_lce_c int
	
	if ((select valor from [dbo].[t_parametros] where keyid = 10)='NO')
	begin
		SELECT 'OK';
		return;
	end 

	
	set @v_lce_c = (select cast(valor2 as integer) from [dbo].[t_parametros] where keyid = 12)
	set @count_prc_c = 0
	
	
	set @count_prc_c = 
	(SELECT count(1) FROM sys.dm_exec_sessions AS s	INNER JOIN sys.dm_exec_requests AS r ON r.session_id = s.session_id	CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS st
	WHERE s.login_name not in (select login from t_check_proc_rdto_login_exclude) 
	and r.blocking_session_id = 0 
	and cast(round(r.total_elapsed_time / (1000.0),2,0) as decimal(10)) > @v_lce_c
	and not exists (select 1 from [dbo].[t_check_proc_rdto_exclude]	where Db_name(st.dbid) = dbname	and Object_schema_name(st.objectid, st.dbid) = obj_sch_name	and Object_name(st.objectid, st.dbid) = obj_name)
	and wait_type not in (select wait_type from [t_check_proc_rdto_wait_exclude])
	)
    
	set @res = 'OK'
    if (@count_prc_c > 0)
	begin
		set @res = 'CRITICAL #LCET > ' + convert(varchar(50), @v_lce_c)
		
		insert into [dbo].[t_check_proc_rdto_log]
		SELECT  CURRENT_TIMESTAMP as currentdate
		, s.session_id SPID
		, s.login_name 
		, s.host_name
		, db_name(r.database_id) as database_name
		, s.program_name
		, r.wait_type	
		, r.wait_resource
		,cast(round(r.wait_time / 1000,2,0) as decimal(10))  'WaitTime (Sec)'
		,cast(round(r.total_elapsed_time / (1000.0),2,0) as decimal(10)) 'LCE (Sec)'
		,st.text AS command_text
		FROM sys.dm_exec_sessions AS s
		INNER JOIN sys.dm_exec_requests AS r ON r.session_id = s.session_id
		CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS st
		WHERE r.session_id != @@SPID
		and r.blocking_session_id = 0 
		and round(r.total_elapsed_time / (1000.0),2,0) > @v_lce_c
		and s.login_name not in (select login from t_check_proc_rdto_login_exclude)
		and not exists (select 1 from [dbo].[t_check_proc_rdto_exclude] where Db_name(st.dbid) = dbname and Object_schema_name(st.objectid, st.dbid) = obj_sch_name and Object_name(st.objectid, st.dbid) = obj_name)
		and wait_type not in (select wait_type from [t_check_proc_rdto_wait_exclude]);
   	end

    select @res;
END

GO
