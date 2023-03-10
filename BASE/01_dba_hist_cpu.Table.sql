/****** Object:  Table [dbo].[dba_hist_cpu]    Script Date: 15/10/2019 15:23:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dba_hist_cpu](
	[Event_Time] [datetime] NOT NULL,
	[SQLServer_CPU_Utilization] [int] NULL,
	[System_Idle] [int] NULL,
	[Other_Process_CPU_Utilization] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].dba_hist_cpu ADD  CONSTRAINT [PK_dba_hist_cpu] PRIMARY KEY CLUSTERED 
(
	[Event_Time]
)ON [PRIMARY]
GO