create table dba_hist_diff_bck (
rundatetime datetime NOT NULL
, job_name nvarchar(50) null
, rundurationminutes int null
, avg_duration int null
,percentage_variable numeric (10,2)
)
ALTER TABLE [dbo].dba_hist_diff_bck ADD  CONSTRAINT [PK_dba_hist_diff_bck] PRIMARY KEY CLUSTERED 
(
	[rundatetime] 
)ON [PRIMARY]
GO
