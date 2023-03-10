/****** Object:  Table [dbo].[t_check_db_size_log]    Script Date: 15/10/2019 15:23:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[t_check_db_size_log](
	[database_id] [int] NOT NULL,
	[Tipo] [nvarchar](3) NULL,
	[database_name] [nvarchar](50) NOT NULL,
	[size] [decimal](12, 2) NULL,
	[max_size] [decimal](12, 2) NULL,
	[percentage_usage] [decimal](12, 2) NULL,
	[critic] [nvarchar](10) NULL,
	[date] [datetime] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].t_check_db_size_log ADD  CONSTRAINT [PK_t_check_db_size_log] PRIMARY KEY CLUSTERED 
(
	[date] desc
)ON [PRIMARY]
GO

