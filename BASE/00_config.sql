USE [master]; 
EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'NumErrorLogs', REG_DWORD, 99;

EXEC sys.sp_configure N'show advanced options', N'1'  RECONFIGURE WITH OVERRIDE;
exec sp_configure 'remote admin connections', 1 RECONFIGURE WITH OVERRIDE;
EXEC sys.sp_configure N'backup compression default', N'1';
EXEC sys.sp_configure N'cost threshold for parallelism', N'50' RECONFIGURE WITH OVERRIDE;
EXEC sys.sp_configure N'show advanced options', N'0'  RECONFIGURE WITH OVERRIDE;
EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'AuditLevel',REG_DWORD, 3;
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_set_sqlagent_properties @jobhistory_max_rows=-1, 
		@jobhistory_max_rows_per_job=-1, 
		@email_save_in_sent_folder=1
GO
