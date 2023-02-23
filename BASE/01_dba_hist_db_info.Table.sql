SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[dba_hist_db_info] (
	DATE DATETIME NOT NULL
	,Servername VARCHAR(128) NULL
	,InstanceName VARCHAR(50) NULL
	,dbname NVARCHAR(128) NOT NULL
	,compatibility_level INT NULL
	,collation_name NVARCHAR(128) NULL
	,user_access_desc NVARCHAR(60) NULL
	,state_desc NVARCHAR(60) NULL
	,recovery_model_desc NVARCHAR(60) NULL
	,page_verify_option_desc NVARCHAR(60) NULL
	,is_read_only INT NULL
	,is_auto_shrink_on INT NULL
	,is_auto_create_stats_on INT NULL
	,is_auto_update_stats_on INT NULL
	,is_read_committed_snapshot_on INT NULL
	,is_parameterization_forced INT NULL
	) ON [PRIMARY]
GO
ALTER TABLE [dbo].dba_hist_db_info ADD  CONSTRAINT [PK_dba_hist_db_info] PRIMARY KEY CLUSTERED 
(
	[DATE] , [dbname]
)ON [PRIMARY]
GO

