/****** Object:  StoredProcedure [dbo].[proc_awr_snap]    Script Date: 15/10/2019 15:23:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[proc_awr_snap] with encryption AS
BEGIN
	set nocount on
	DECLARE @v_snap integer
	declare @sql_dm_os_sys_info nvarchar(max)
	declare @sql_dm_io_virtual_file_stats nvarchar(max)
	insert into dba_hist_snapshot (end_interval_time) values(getdate())
	select @v_snap = max(snap_id) from dba_hist_snapshot
if (cast(@@version as varchar (25)) = 'Microsoft SQL Server 2008') 
begin--2008

	set @sql_dm_os_sys_info ='insert into dba_hist_dm_os_sys_info
	SELECT 	'+ cast(@v_snap as varchar(15))+' ,cpu_ticks,ms_ticks,cpu_count,hyperthread_ratio,physical_memory_in_bytes,virtual_memory_in_bytes,bpool_committed,bpool_commit_target,bpool_visible
	,stack_size_in_bytes,os_quantum	,os_error_mode,os_priority_class,max_workers_count,scheduler_count,scheduler_total_count,deadlock_monitor_serial_number
	,sqlserver_start_time_ms_ticks,sqlserver_start_time,affinity_type	,affinity_type_desc,process_kernel_time_ms,process_user_time_ms,time_source
	,time_source_desc,virtual_machine_type,virtual_machine_type_desc,NULL,NULL,NULL,NULL
	FROM sys.dm_os_sys_info'


	set @sql_dm_io_virtual_file_stats='insert into dba_hist_dm_io_virtual_file_stats
	select '+  cast(@v_snap as varchar(15)) +', m.type, d.database_id, d.sample_ms, sum(d.num_of_reads), sum(d.num_of_bytes_read), sum(d.io_stall_read_ms), 0
	, sum(d.num_of_writes), sum(d.num_of_bytes_written), sum(d.io_stall_write_ms), 0, sum(d.io_stall), sum(d.size_on_disk_bytes)
	from sys.dm_io_virtual_file_stats (null,null) d
		join sys.master_files m
			on d.database_id=m.database_id and d.file_id=m.file_id
	group by m.type, d.database_id,d.sample_ms
	order by d.database_id, m.type asc'
end
else
if (cast(@@version as varchar (25)) = 'Microsoft SQL Server 2014') 
begin--2014

	set @sql_dm_os_sys_info ='insert into dba_hist_dm_os_sys_info
	SELECT 	'+ cast(@v_snap as varchar(15))+' ,cpu_ticks,ms_ticks,cpu_count,hyperthread_ratio,physical_memory_kb,virtual_memory_kb,null,null,null
	,stack_size_in_bytes,os_quantum	,os_error_mode,os_priority_class,max_workers_count,scheduler_count,scheduler_total_count,deadlock_monitor_serial_number
	,sqlserver_start_time_ms_ticks,sqlserver_start_time,affinity_type	,affinity_type_desc,process_kernel_time_ms,process_user_time_ms,time_source
	,time_source_desc,virtual_machine_type,virtual_machine_type_desc,NULL,NULL,NULL,NULL
	FROM sys.dm_os_sys_info'


	set @sql_dm_io_virtual_file_stats='insert into dba_hist_dm_io_virtual_file_stats
	select '+  cast(@v_snap as varchar(15)) +', m.type, d.database_id, d.sample_ms, sum(d.num_of_reads), sum(d.num_of_bytes_read), sum(d.io_stall_read_ms), 0
	, sum(d.num_of_writes), sum(d.num_of_bytes_written), sum(d.io_stall_write_ms), 0, sum(d.io_stall), sum(d.size_on_disk_bytes)
	from sys.dm_io_virtual_file_stats (null,null) d
		join sys.master_files m
			on d.database_id=m.database_id and d.file_id=m.file_id
	group by m.type, d.database_id,d.sample_ms
	order by d.database_id, m.type asc'
end
else
 -- 2012++
begin
	

	set @sql_dm_os_sys_info='insert into dba_hist_dm_os_sys_info
	select '+  cast(@v_snap as varchar(15)) +', cpu_ticks, ms_ticks, cpu_count, hyperthread_ratio, physical_memory_kb, virtual_memory_kb, committed_kb, committed_target_kb
	, visible_target_kb, stack_size_in_bytes,os_quantum, os_error_mode, os_priority_class, max_workers_count, scheduler_count, scheduler_total_count
	, deadlock_monitor_serial_number, sqlserver_start_time_ms_ticks, sqlserver_start_time, affinity_type, affinity_type_desc, process_kernel_time_ms
	, process_user_time_ms, time_source, time_source_desc, virtual_machine_type, virtual_machine_type_desc,NULL,NULL,NULL,NULL
	from sys.dm_os_sys_info'

	set @sql_dm_io_virtual_file_stats='insert into dba_hist_dm_io_virtual_file_stats
	select '+  cast(@v_snap as varchar(15)) +', m.type, d.database_id, d.sample_ms, sum(d.num_of_reads), sum(d.num_of_bytes_read), sum(d.io_stall_read_ms), 0
	, sum(d.num_of_writes), sum(d.num_of_bytes_written), sum(d.io_stall_write_ms), 0, sum(d.io_stall), sum(d.size_on_disk_bytes)
	from sys.dm_io_virtual_file_stats (null,null) d
		join sys.master_files m
			on d.database_id=m.database_id and d.file_id=m.file_id
	group by m.type, d.database_id,d.sample_ms
	order by d.database_id, m.type asc'
end
	
	insert into dba_hist_dm_exec_procedure_stats
	select @v_snap,
	a.database_id,a.object_id,a.type,a.type_desc,a.sql_handle,a.plan_handle,a.cached_time,a.last_execution_time,a.execution_count,a.total_worker_time,a.
	last_worker_time,a.min_worker_time,a.max_worker_time,a.total_physical_reads,a.last_physical_reads,a.min_physical_reads,a.max_physical_reads,a.
	total_logical_writes,a.last_logical_writes,a.min_logical_writes,a.max_logical_writes,a.total_logical_reads,a.last_logical_reads,a.min_logical_reads,a.
	max_logical_reads,a.total_elapsed_time,a.last_elapsed_time,a.min_elapsed_time,a.max_elapsed_time
	from sys.dm_exec_procedure_stats a where database_id <> 32767 and database_id > 4
	
	insert into dba_hist_dm_os_wait_stats
	select @v_snap, wait_type, waiting_tasks_count, wait_time_ms, max_wait_time_ms, signal_wait_time_ms
	from sys.dm_os_wait_stats where waiting_tasks_count<>0
	
	exec sp_executesql @sql_dm_os_sys_info
	
    exec sp_executesql @sql_dm_io_virtual_file_stats
	
	insert into dba_hist_dm_os_sys_memory
	select @v_snap, total_physical_memory_kb, available_physical_memory_kb, total_page_file_kb, available_page_file_kb, system_cache_kb, kernel_paged_pool_kb, kernel_nonpaged_pool_kb
	, system_high_memory_signal_state, system_low_memory_signal_state, system_memory_state_desc
	from sys.dm_os_sys_memory

	exec proc_cpu
	exec proc_hist_inst_info
	exec proc_hist_db_info
END
GO
