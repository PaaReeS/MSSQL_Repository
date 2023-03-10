/****** Object:  Table [dbo].[t_check_jobs]    Script Date: 15/10/2019 15:26:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[t_check_jobs](
	[owner] [nvarchar](100) NULL,
	[job_name] [nvarchar](100) NOT NULL,
	[enabled] [nvarchar](1) NULL,
	[level_inc] [nvarchar](100) NULL,
	[limit_failures] [int] NULL,
	[interval_min] [int] NULL,
	[fecha_fin_exclusion] [datetime] NULL,
	[responsible_dept] [nvarchar](100) NULL,
	[responsible_email] [nvarchar](100) NULL 
) ON [PRIMARY]
GO
ALTER TABLE [dbo].t_check_jobs ADD  CONSTRAINT [PK_t_check_jobs] PRIMARY KEY CLUSTERED 
(
	[job_name]
)ON [PRIMARY]
GO
