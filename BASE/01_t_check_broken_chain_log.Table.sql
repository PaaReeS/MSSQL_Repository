
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[t_check_broken_chain_log](
	load_date datetime not null,
	database_name sysname not null
	, backup_finish_date datetime
	, database_backup_lsn numeric(25,0)
	, lsn_full numeric(25,0)
) ON [PRIMARY]
GO
ALTER TABLE [dbo].t_check_broken_chain_log ADD  CONSTRAINT [PK_t_check_broken_chain_log] PRIMARY KEY CLUSTERED 
(
	[load_date],[database_name]
)ON [PRIMARY]
GO