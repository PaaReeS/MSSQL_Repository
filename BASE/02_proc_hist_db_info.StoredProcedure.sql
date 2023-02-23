SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[proc_hist_db_info] with encryption
as
begin
SET NOCOUNT ON

insert into [dba_hist_db_info](DATE, Servername,InstanceName, dbname, compatibility_level, collation_name,user_access_desc,state_desc,recovery_model_desc,page_verify_option_desc,is_read_only,is_auto_shrink_on,is_auto_create_stats_on,is_auto_update_stats_on,is_read_committed_snapshot_on,is_parameterization_forced)
select getdate()
, * 
from (
	SELECT
	cast(@@SERVERNAME as varchar(50)) as servername
	,cast(@@SERVICENAME as varchar(50)) as instancename
	,name
	,compatibility_level
	,collation_name
	,user_access_desc COLLATE DATABASE_DEFAULT as user_access_desc
	,state_desc COLLATE DATABASE_DEFAULT as state_desc
	,recovery_model_desc COLLATE DATABASE_DEFAULT as recovery_model_desc
	,page_verify_option_desc COLLATE DATABASE_DEFAULT as page_verify_option_desc
	,is_read_only
	,is_auto_shrink_on
	,is_auto_create_stats_on
	,is_auto_update_stats_on
	,is_read_committed_snapshot_on
	,is_parameterization_forced
	FROM sys.databases 
	except
	select * 
	from (
		select top (select count(*) from sys.databases) Servername,InstanceName, dbname, compatibility_level, collation_name,user_access_desc,state_desc,recovery_model_desc,page_verify_option_desc,is_read_only,is_auto_shrink_on,is_auto_create_stats_on,is_auto_update_stats_on,is_read_committed_snapshot_on,is_parameterization_forced
		from dba_hist_db_info  order by DATE desc
		) as a
) as c
end;
GO
