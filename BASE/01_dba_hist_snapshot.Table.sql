/****** Object:  Table [dbo].[dba_hist_snapshot]    Script Date: 15/10/2019 15:23:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dba_hist_snapshot](
	[snap_id] [int] IDENTITY(1,1) NOT NULL,
	[end_interval_time] [datetime] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[dba_hist_snapshot] ADD  CONSTRAINT [PK_dba_hist_snapshot] PRIMARY KEY CLUSTERED 
(
	[snap_id] desc
)ON [PRIMARY]
GO 