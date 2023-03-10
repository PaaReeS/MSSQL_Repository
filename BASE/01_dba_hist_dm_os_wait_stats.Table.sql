/****** Object:  Table [dbo].[dba_hist_dm_os_wait_stats]    Script Date: 15/10/2019 15:23:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dba_hist_dm_os_wait_stats](
	[snap_id] [int] NOT NULL,
	[wait_type] [nvarchar](60) NOT NULL,
	[waiting_tasks_count] [bigint] NULL,
	[wait_time_ms] [bigint] NULL,
	[max_wait_time_ms] [bigint] NULL,
	[signal_wait_time_ms] [bigint] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IDX_dba_hist_dm_os_wait_stats_1]    Script Date: 15/10/2019 15:23:36 ******/
ALTER TABLE [dbo].dba_hist_dm_os_wait_stats ADD  CONSTRAINT [PK_dba_hist_dm_os_wait_stats] PRIMARY KEY CLUSTERED 
(
	[snap_id],[wait_type]
)ON [PRIMARY]
GO