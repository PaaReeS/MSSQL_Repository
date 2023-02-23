create procedure graf_CPU with encryption
as
begin
select 
System_Idle
, SQLServer_CPU_Utilization
, 100 - System_Idle - SQLServer_CPU_Utilization as SQLServer_CPU_Other
from (
	SELECT TOP 1 
	record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') AS System_Idle
	, record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int') AS SQLServer_CPU_Utilization
	FROM (
		SELECT 
		timestamp
		, convert(XML, record) AS record
		FROM sys.dm_os_ring_buffers
		WHERE ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR' AND record LIKE '%<SystemHealth>%'
		) AS x
		order by timestamp desc
	) as z
end;
go

