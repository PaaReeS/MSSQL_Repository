
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[t_his_suspect_pages_log](
    [date] [datetime] NULL,
	[db_id] integer NULL,
	[db_name] [nvarchar](60) NULL,
	[file_id] [integer] NULL,
	[file_name] [nvarchar](60) NULL,
	[page_id] [bigint] NULL,
	[event_type] [integer] NULL,
	[event_type_desc] [nvarchar](25) NULL,
	[error_count] [integer] NULL,
	[last_update_date] datetime NULL,
	[Notas_DBA] [nvarchar](250) NULL
) ON [PRIMARY]
GO


