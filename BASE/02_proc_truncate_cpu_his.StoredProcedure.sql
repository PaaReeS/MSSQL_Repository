SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure proc_truncate_cpu_his with encryption
as
begin
set nocount on
create table #temptab (
	[event_time] [datetime] null,
	[SQLServer_CPU_Utilization] [int] null,
	[system_idle] [int] null,
	[other_process_cpu_utilization] [int] null
);
insert into #temptab
select 
cast(e2 as datetime)
, sum(SQLServer_CPU_Utilization)/COUNT(*) SQLServer_CPU_Utilization
, sum(System_Idle)/COUNT(*) System_Idle
, sum(Other_Process_CPU_Utilization)/COUNT(*) Other_Process_CPU_Utilization
from(
	select 
	Event_Time
	,CONVERT(VARCHAR(10), Event_Time, 112)+ ' '  + CONVERT(VARCHAR(3), Event_Time, 108)+ '00' as e2
	, SQLServer_CPU_Utilization
	, System_Idle
	, Other_Process_CPU_Utilization
	from dba_hist_cpu
	where Event_Time < getdate()-365
	) as z
group by e2

delete from dba_hist_cpu where Event_Time < getdate()-365
insert into dba_hist_cpu select * from #temptab


drop table #temptab

end
go
