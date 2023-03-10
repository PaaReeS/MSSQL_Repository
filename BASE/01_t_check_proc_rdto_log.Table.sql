/****** Object:  Table [dbo].[t_check_proc_rdto_log]    Script Date: 15/10/2019 15:23:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[t_check_proc_rdto_log](
	[load_date] [datetime] NOT NULL,
	[spid] [int] NOT NULL,
	[login] [nvarchar](50) NULL,
	[hostname] [nvarchar](60) NULL,
	[database] [nvarchar](60) NULL,
	[program] [nvarchar](100) NULL,
	[wait_type] [nvarchar](50) NULL,
	[wait_resource] [nvarchar](80) NULL,
	[waittime_sec] [int] NULL,
	[lce_sec] [int] NULL,
	[command_text] [nvarchar](max) NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].t_check_proc_rdto_log ADD  CONSTRAINT [PK_t_check_proc_rdto_log] PRIMARY KEY CLUSTERED 
(
	[load_date],[spid]
)ON [PRIMARY]
GO
