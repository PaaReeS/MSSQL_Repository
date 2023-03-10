/****** Object:  Table [dbo].[t_check_proc_lock_log]    Script Date: 15/10/2019 15:23:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[t_check_proc_lock_log](
	Date [datetime] NOT NULL,
	Database_Name [nvarchar](50) NULL,
	SPID_Blocking [int] NULL,
	LOGIN_Blocking [nvarchar](50) NULL,
	HOST_Blocking [nvarchar](50) NULL,
	IP_Blocking [nvarchar](50) NULL, 
	SPID_Blocked [int] NULL,
	LOGIN_Blocked [nvarchar](50) NULL,
	HOST_Blocked [nvarchar](50) NULL,
	IP_Blocked [nvarchar](50) NULL, 
	LCE_Blocked_sec [int] NULL,
	Wait_type [nvarchar](30) NULL,
	Wait_resource [nvarchar](50) NULL,
	Blocking_TEXT [nvarchar](MAX) NULL,
	Blocked_TEXT [nvarchar](MAX) NULL
) ON [PRIMARY]
GO

