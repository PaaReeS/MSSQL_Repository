/****** Object:  Table [dbo].[dba_hist_dm_os_sys_info]    Script Date: 15/10/2019 15:23:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dba_hist_dm_os_sys_info](
	[snap_id] [int] NOT NULL,
	[cpu_ticks] [bigint] NULL,
	[ms_ticks] [bigint] NULL,
	[cpu_count] [int] NULL,
	[hyperthread_ratio] [int] NULL,
	[physical_memory_kb] [bigint] NULL,
	[virtual_memory_kb] [bigint] NULL,
	[committed_kb] [int] NULL,
	[committed_target_kb] [int] NULL,
	[visible_target_kb] [int] NULL,
	[stack_size_in_bytes] [int] NULL,
	[os_quantum] [bigint] NULL,
	[os_error_mode] [int] NULL,
	[os_priority_class] [int] NULL,
	[max_workers_count] [int] NULL,
	[scheduler_count] [int] NULL,
	[scheduler_total_count] [int] NULL,
	[deadlock_monitor_serial_number] [int] NULL,
	[sqlserver_start_time_ms_ticks] [bigint] NULL,
	[sqlserver_start_time] [datetime] NULL,
	[affinity_type] [int] NULL,
	[affinity_type_desc] [nvarchar](60) NULL,
	[process_kernel_time_ms] [bigint] NULL,
	[process_user_time_ms] [bigint] NULL,
	[time_source] [int] NULL,
	[time_source_desc] [nvarchar](60) NULL,
	[virtual_machine_type] [int] NULL,
	[virtual_machine_type_desc] [nvarchar](60) NULL,
	[softnuma_configuration] [int] NULL,
	[softnuma_configuration_desc] [nvarchar](60) NULL,
	[sql_memory_model] [int] NULL,
	[sql_memory_model_desc] [nvarchar](120) NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].dba_hist_dm_os_sys_info ADD  CONSTRAINT [PK_dba_hist_dm_os_sys_info] PRIMARY KEY CLUSTERED 
(
	[snap_id]
)ON [PRIMARY]
GO
