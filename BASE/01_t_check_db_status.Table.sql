
/****** Object:  Table [dbo].[t_check_db_status]    Script Date: 03/02/2020 16:50:33 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[t_check_db_status](
	[db_name] [nvarchar](100) NOT NULL,
	[active] [nvarchar](1) NOT NULL,
	[last_update_date] datetime NULL,
	[notas_DBA] [nvarchar](250) NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].t_check_db_status ADD  CONSTRAINT [PK_t_check_db_status] PRIMARY KEY CLUSTERED 
(
	[db_name] 
)ON [PRIMARY]
GO


