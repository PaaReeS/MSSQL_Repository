/****** Object:  Table [dbo].[t_check_jobs_log]    Script Date: 15/10/2019 15:23:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[t_check_jobs_log](
	[load_date] [datetime] NOT NULL,
	[owner] [nvarchar](100) NULL,
	[job_name] [nvarchar](100) NOT NULL,
	[level_inc] [nvarchar](100) NULL,
	[error_text] [nvarchar](255) NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].t_check_jobs_log ADD  CONSTRAINT [PK_t_check_jobs_log] PRIMARY KEY CLUSTERED 
(
	[load_date],[job_name]
)ON [PRIMARY]
GO