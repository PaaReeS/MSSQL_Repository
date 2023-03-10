/****** Object:  Table [dbo].[dba_hist_dm_os_sys_memory]    Script Date: 15/10/2019 15:23:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dba_hist_dm_os_sys_memory](
	[snap_id] [int] NOT NULL,
	[total_physical_memory_kb] [bigint] NULL,
	[available_physical_memory_kb] [bigint] NULL,
	[total_page_file_kb] [bigint] NULL,
	[available_page_file_kb] [bigint] NULL,
	[system_cache_kb] [bigint] NULL,
	[kernel_paged_pool_kb] [bigint] NULL,
	[kernel_nonpaged_pool_kb] [bigint] NULL,
	[system_high_memory_signal_state] [bit] NULL,
	[system_low_memory_signal_state] [bit] NULL,
	[system_memory_state_desc] [nvarchar](256) NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].dba_hist_dm_os_sys_memory ADD  CONSTRAINT [PK_dba_hist_dm_os_sys_memory] PRIMARY KEY CLUSTERED 
(
	[snap_id]
)ON [PRIMARY]
GO