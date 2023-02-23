SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dba_hist_inst_info](
	Date datetime not null,
	Servername varchar(50) null,
	InstanceName varchar(50) null,
	SQLVersion varchar(150) null,
	Instance_Collation varchar(50) null,
	vcpu int null,
	Last_restart_date datetime null,
	Instance_max_memory_MB int null,
	Cost_threshold_for_parallelism int null,
	Max_degree_of_parallelism int null,
	Opt4AdHoc int null,
	PriorityBoost int null
) ON [PRIMARY]
GO
ALTER TABLE [dbo].dba_hist_inst_info ADD  CONSTRAINT [PK_dba_hist_inst_info] PRIMARY KEY CLUSTERED 
(
	[date]
)ON [PRIMARY]
GO





 