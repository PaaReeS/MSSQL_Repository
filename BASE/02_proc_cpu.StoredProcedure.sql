/****** Object:  StoredProcedure [dbo].[proc_cpu]    Script Date: 15/10/2019 15:23:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[proc_cpu] with encryption
as
begin
	SET NOCOUNT ON
	DECLARE @ts BIGINT;
	SELECT @ts = (SELECT cpu_ticks / (cpu_ticks / ms_ticks)	FROM sys.dm_os_sys_info);
	
	insert into [dba_hist_cpu] (Event_Time, SQLServer_CPU_Utilization, System_Idle, Other_Process_CPU_Utilization)
	SELECT
	Event_Time
	, SQLServer_CPU_Utilization
	, System_Idle
	, Other_Process_CPU_Utilization
	FROM(
		SELECT 
		 dateadd(ms, - 1 * (@ts- [timestamp]), GetDate()) AS Event_Time
		, SQLServer_CPU_Utilization
		, System_Idle
		, 100 - System_Idle - SQLServer_CPU_Utilization AS Other_Process_CPU_Utilization
		FROM (
			SELECT record.value('(./Record/@id)[1]', 'int') AS record_id
				, record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') AS System_Idle
				, record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int') AS SQLServer_CPU_Utilization
				, TIMESTAMP
			FROM (
				SELECT TIMESTAMP
					, convert(XML, record) AS record
				FROM sys.dm_os_ring_buffers
				WHERE ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR' AND record LIKE '%<SystemHealth>%'
			) AS x
		) AS y
	) as z
	where Event_Time > (select isnull(max(Event_Time),0) from [dba_hist_cpu])
	ORDER BY Event_Time DESC
end;
GO
