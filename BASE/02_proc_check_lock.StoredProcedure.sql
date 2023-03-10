/****** Object:  StoredProcedure [dbo].[proc_check_lock]    Script Date: 15/10/2019 15:23:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[proc_check_lock] with encryption
AS
BEGIN
--select 'OK'
--return
set nocount on
	Declare @count_prc_w int
	Declare @count_prc_c int
	Declare @res nvarchar(255)

	Declare @v_lce_w int
	Declare @v_lce_c int
	Declare @v_prc_w int
	Declare @v_prc_c int
	
	set @v_lce_w = (select cast(valor as integer) from [dbo].[t_parametros] where keyid = 22)
	set @v_lce_c = (select cast(valor2 as integer) from [dbo].[t_parametros] where keyid = 22)
	set @v_prc_w = (select cast(valor as integer) from [dbo].[t_parametros] where keyid = 24)
	set @v_prc_c = (select cast(valor2 as integer) from [dbo].[t_parametros] where keyid = 24)

	set @count_prc_w = 0
	set @count_prc_c = 0
	
	set @count_prc_w = 
	(SELECT count(1)
	FROM sys.dm_exec_sessions AS s
		INNER JOIN sys.dm_exec_requests AS r ON r.session_id = s.session_id
		CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS st
	WHERE r.blocking_session_id > 0 
	and r.wait_time/1000 > @v_lce_w
	and not exists	(select 1 from [dbo].[t_check_proc_lock_exclude] where Db_name(st.dbid) = dbname and Object_schema_name(st.objectid, st.dbid) = obj_sch_name and Object_name(st.objectid, st.dbid) = obj_name)
	and not exists (select 1 from [dbo].[t_check_proc_lock_login_exclude] t where s.login_name=t.login)
	)
	
	set @count_prc_c = 
	(SELECT count(1)
	FROM sys.dm_exec_sessions AS s
		INNER JOIN sys.dm_exec_requests AS r ON r.session_id = s.session_id
		CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS st
	WHERE r.blocking_session_id > 0 
	and r.wait_time/1000 > @v_lce_c
	and not exists	(select 1 from [dbo].[t_check_proc_lock_exclude] where Db_name(st.dbid) = dbname and Object_schema_name(st.objectid, st.dbid) = obj_sch_name and Object_name(st.objectid, st.dbid) = obj_name)
	and not exists (select 1 from [dbo].[t_check_proc_lock_login_exclude] t where s.login_name=t.login)
	)
	
	insert into [dbo].[t_check_proc_lock_log]
	(Date,Database_Name,SPID_Blocking,LOGIN_Blocking,HOST_Blocking,IP_Blocking,SPID_Blocked,LOGIN_Blocked,HOST_Blocked,IP_Blocked,LCE_Blocked_sec,Wait_type,Wait_resource,Blocking_TEXT,Blocked_TEXT)
	SELECT  
	sysdatetime() as date
	, db_name(blocked.database_id) as database_name
	, ec.session_id as spid_blocking 
	, sess.login_name as login_blocking
	, sess.host_name as host_blocking
	, ec.client_net_address as ip_blocking
	, blocked.session_id as spid_blocked
	, sess2.login_name as login_blocked
	, sess2.host_name as host_blocked
	, ec2.client_net_address as ip_blocked
	, blocked.wait_time/1000 as lce_blocked_sec
	, blocked.wait_type as wait_type
	, blocked.wait_resource as wait_resource
	, blockingsql.text as blocking_text
	, blockedsql.text as blocked_text
	from sys.dm_exec_connections as ec  
		join sys.dm_exec_requests as blocked 
			on ec.session_id = blocked.blocking_session_id
		join sys.dm_exec_sessions sess  
			on ec.session_id = sess.session_id
		join sys.dm_exec_sessions sess2  
			on blocked.session_id = sess2.session_id
			join sys.dm_exec_connections as ec2
			on ec2.session_id = blocked.session_id
		cross apply sys.dm_exec_sql_text(ec.most_recent_sql_handle) as blockingsql
		cross apply sys.dm_exec_sql_text(blocked.sql_handle) as blockedsql
	WHERE blocked.wait_time/1000 > @v_lce_w;
    
	set @res = 'OK'
	if (@count_prc_c >= 1)
    begin
		set @res = 'CRITICAL #Procs: ' + convert(varchar(5), @count_prc_c) + ' - LCE > ' + convert(varchar(50), @v_lce_c)
	end
	else
		if (@count_prc_w >= @v_prc_c)
		begin
			set @res = 'CRITICAL #Procs: ' + convert(varchar(5), @count_prc_w) + ' - LCE > ' + convert(varchar(50), @v_lce_w)
		end
	else
	begin
		if (@count_prc_w >= @v_prc_w)
		begin
			set @res = 'WARNING #Procs: ' + convert(varchar(50), @count_prc_w) + ' - LCE > ' + convert(varchar(50), @v_lce_w)
		end
   	end

	select @res;	
	
END


GO
