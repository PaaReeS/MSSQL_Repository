/****** Object:  Table [dbo].[t_check_proc_lock_exclude]    Script Date: 15/10/2019 15:23:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[t_check_proc_lock_exclude](
	[dbname] [nvarchar](50) NULL,
	[obj_sch_name] [nvarchar](50) NULL,
	[obj_name] [nvarchar](50) NULL
) ON [PRIMARY]
GO
