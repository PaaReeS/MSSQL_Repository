/****** object:  table [dbo].[t_his_auto_grow_log]    script date: 15/10/2019 15:23:36 ******/
set ansi_nulls on
go
set quoted_identifier on
go
create table [dbo].[t_his_auto_grow_log](
	[start_time] [datetime] NOT null,
	[event_name] [nvarchar](30) NOT null,
	[db_name] [nvarchar](60) NOT null,
	[file_name] [nvarchar](60) NOT null,
	[growth_mb] [nvarchar](15) null,
	[ms] [nvarchar](15) null
) 
go
ALTER TABLE [dbo].t_his_auto_grow_log ADD  CONSTRAINT [PK_t_his_auto_grow_log] PRIMARY KEY CLUSTERED 
(
	[start_time],[event_name],[db_name],[file_name]
)ON [PRIMARY]
GO
