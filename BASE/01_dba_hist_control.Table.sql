/****** Object:  Table [dbo].[dba_hist_control]    Script Date: 15/10/2019 15:26:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dba_hist_control](
	[procname] [varchar](50) NOT NULL,
	[metric_code] [varchar](50) NOT NULL,
	[metric_base] [varchar](50) NOT NULL,
	[metric_name] [varchar](50) NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].dba_hist_control ADD  CONSTRAINT [PK_dba_hist_control] PRIMARY KEY CLUSTERED 
(
	[procname],[metric_code],[metric_base]
)ON [PRIMARY]
GO

