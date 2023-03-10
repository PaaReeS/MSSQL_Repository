/****** Object:  Table [dbo].[dba_hist_dm_io_virtual_file_stats]    Script Date: 15/10/2019 15:23:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dba_hist_dm_io_virtual_file_stats](
	[snap_id] [int] NOT NULL,
	[type] [int] NOT NULL,
	[database_id] [smallint] NOT NULL,
	[sample_ms] [bigint] NULL,
	[num_of_reads] [bigint] NULL,
	[num_of_bytes_read] [bigint] NULL,
	[io_stall_read_ms] [bigint] NULL,
	[io_stall_queued_read_ms] [bigint] NULL,
	[num_of_writes] [bigint] NULL,
	[num_of_bytes_written] [bigint] NULL,
	[io_stall_write_ms] [bigint] NULL,
	[io_stall_queued_write_ms] [bigint] NULL,
	[io_stall] [bigint] NULL,
	[size_on_disk_bytes] [bigint] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].dba_hist_dm_io_virtual_file_stats ADD  CONSTRAINT [PK_dba_hist_dm_io_virtual_file_stats] PRIMARY KEY CLUSTERED 
(
	[snap_id],[type], [database_id]
)ON [PRIMARY]
GO
