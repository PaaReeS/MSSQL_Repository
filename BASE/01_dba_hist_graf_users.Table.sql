
create table dba_hist_graf_users(
	[end_interval_time] [datetime] NULL
	,[db] [nvarchar](60) NULL
	,[Total] [int] NOT NULL
	,[Dormant] [int] NOT NULL
	,[Running] [int] NOT NULL
	,[Background] [int] NOT NULL
	,[Rollback] [int] NOT NULL
	,[Pending] [int] NOT NULL
	,[Runnable] [int] NOT NULL
	,[Spinloop] [int] NOT NULL
	,[Suspended] [int] NOT NULL
	,[Sleeping] [int] NOT NULL
) ON [PRIMARY]
GO	
	
