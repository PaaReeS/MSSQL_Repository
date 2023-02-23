
/****** Object:  Table [dbo].[t_check_db_status_log]    Script Date: 16/10/2019 13:40:21 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[t_check_db_status_log](
	[db_name] [nvarchar](60) NOT NULL,
	[state] [nvarchar](60) NULL, 
	[date] [datetime] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].t_check_db_status_log ADD  CONSTRAINT [PK_t_check_db_status_log] PRIMARY KEY CLUSTERED 
(
	[date]
)ON [PRIMARY]
GO



