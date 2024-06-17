create table dba_hist_diff (
rundatetime datetime NOT NULL
, job_name nvarchar(50) NOT NULL
, rundurationminutes int null
, avg_duration int null
,percentage_variable numeric (10,2)
)
ALTER TABLE [dbo].dba_hist_diff ADD  CONSTRAINT [PK_dba_hist_diff] PRIMARY KEY CLUSTERED 
(
	[rundatetime], [job_name]
)ON [PRIMARY]
GO
