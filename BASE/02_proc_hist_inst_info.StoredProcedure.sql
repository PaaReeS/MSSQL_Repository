SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[proc_hist_inst_info] with encryption
as
begin
SET NOCOUNT ON

insert into [dba_hist_inst_info] (Date,Servername,InstanceName,SQLVersion,Instance_Collation,vcpu,Last_restart_date,Instance_max_memory_MB,Cost_threshold_for_parallelism,Max_degree_of_parallelism,Opt4AdHoc,PriorityBoost )
select getdate()
, * 
from (
	SELECT
		cast(@@SERVERNAME as varchar(50)) as servername
		, cast(@@SERVICENAME as varchar(50)) as instancename
		, cast(@@VERSION as varchar(150)) as version
		, cast(SERVERPROPERTY('collation') as varchar(50)) as collation
		, cpu_count as vcpu
		, sqlserver_start_time 
		, (select cast(value_in_use as int) from sys.configurations where name = 'max server memory (MB)') as maxmemory
		, (select cast(value_in_use as int) from sys.configurations where name = 'cost threshold for parallelism') as ParaCostTreshold
		, (select cast(value_in_use as int) from sys.configurations where name = 'max degree of parallelism') as MaxParaDegree
		, (select cast(value_in_use as int) from sys.configurations where name = 'optimize for ad hoc workloads') as Opt4AdHoc
		, (select cast(value_in_use as int) from sys.configurations where name = 'priority boost') as PriorityBoost
		FROM sys.dm_os_sys_info 
	except
	select * 
	from (
		select top 1 Servername,InstanceName,SQLVersion,Instance_Collation,vcpu,Last_restart_date,Instance_max_memory_MB,Cost_threshold_for_parallelism,Max_degree_of_parallelism,Opt4AdHoc,PriorityBoost 
		from dba_hist_inst_info  order by Date desc
		) as a
) as c
end;
GO
