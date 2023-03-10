

USE [master]
GO
CREATE LOGIN [dba_mon] WITH PASSWORD=N'dba_mon', DEFAULT_DATABASE=[DBA], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
ALTER LOGIN [dba_mon] ENABLE
GO
GRANT CONNECT ANY DATABASE TO [dba_mon]
GO
GRANT VIEW SERVER STATE TO [dba_mon]
GO
GRANT VIEW ANY DEFINITION TO [dba_mon]
GO


USE [msdb]
GO
CREATE USER [dba_mon] FOR LOGIN [dba_mon]
GO
GRANT SELECT ON [dbo].[sysjobhistory] TO [dba_mon]
go
GRANT SELECT ON [dbo].[sysjobs] TO [dba_mon]
go
GRANT EXECUTE ON [dbo].[agent_datetime] TO [dba_mon]
go
GRANT SELECT ON msdb.[dbo].[sysschedules] TO dba_mon
GO
GRANT SELECT ON msdb.[dbo].[sysjobsteps] TO dba_mon
GO
GRANT SELECT ON msdb.[dbo].[sysjobschedules] TO dba_mon
GO

USE [DBA]
GO
CREATE USER [dba_mon] FOR LOGIN [dba_mon]
GO
GRANT EXECUTE ON [dbo].[proc_check_db_log_size] TO [dba_mon] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[proc_check_db_data_size] TO [dba_mon] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[proc_check_db_file_size] TO [dba_mon] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[proc_check_job] TO [dba_mon] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[proc_check_lock] TO [dba_mon] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[proc_check_rdto] TO [dba_mon] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[proc_check_db_status] TO [dba_mon] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[graf_CPU] TO [dba_mon] AS [dbo]
GO

GRANT EXECUTE ON [dbo].[graf_MEM] TO [dba_mon] AS [dbo]
GO

GRANT EXECUTE ON [dbo].[graf_USERS] TO [dba_mon] AS [dbo]
GO

GRANT EXECUTE ON [dbo].[graf_WAIT] TO [dba_mon] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[sp_report] TO [dba_mon];  
GO
GRANT EXECUTE ON [dbo].[sp_report2] TO [dba_mon];  
GO
GRANT Select on [dbo].[dba_hist_dm_io_virtual_file_stats] TO [dba_mon];  
GO
grant execute on sp_Inventario to dba_mon
go
