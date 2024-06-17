USE [msdb]
GO
IF(EXISTS(select name from msdb.dbo.sysjobs where name ='DBA_Cleanup'))
EXEC msdb.dbo.sp_delete_job @job_name=N'DBA_Cleanup', @delete_unused_schedule=1



BEGIN TRANSACTION

declare @ruta as nvarchar(500);
declare @OutputCmd as nvarchar(500);
declare @rutaOutputFile as nvarchar(500);
declare @rutaCommandlogCleanup as nvarchar(500);
set @ruta=(SELECT left( convert(nvarchar(500), SERVERPROPERTY('ErrorLogFileName')) , LEN (convert(nvarchar(500), SERVERPROPERTY('ErrorLogFileName')))- 9 ) );
set @rutaOutputFile=@ruta + '\DBA_Output_File_Cleanup_$(ESCAPE_SQUOTE(STRTDT))_$(ESCAPE_SQUOTE(STRTTM)).txt';
set @rutaCommandlogCleanup=@ruta + '\DBA_CommandLog_Cleanup_$(ESCAPE_SQUOTE(STRTDT))_$(ESCAPE_SQUOTE(STRTTM)).txt';
set @OutputCmd='cmd /q /c "For /F "tokens=1 delims=" %v In (''ForFiles /P "'+@ruta+'" /m *_*_*_*.txt /d -90 2^>^&1'') do if EXIST "'+@ruta+'"\%v echo del "'+@ruta+'"\%v& del "'+@ruta+'"\%v"'




DECLARE @jobId BINARY(16)
EXEC  msdb.dbo.sp_add_job @job_name=N'DBA_Cleanup', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No hay ninguna descripción.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT


EXEC  msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'DBA_Output_File_Cleanup', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'CmdExec',
		@command=@OutputCmd, 
		@output_file_name=@rutaOutputFile, 
		@flags=0

EXEC msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1

EXEC msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'DBA_CommandLog_Cleanup', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DELETE FROM [dbo].[CommandLog] WHERE StartTime < DATEADD(dd,-30,GETDATE())', 
		@database_name=N'DBA', 
		@output_file_name=@rutaCommandlogCleanup , 
		@flags=0
        
EXEC msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'DBA_Purge_Jobs_History', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'declare @dt datetime 
		select  @dt =  CONVERT(date, getdate() -60)
		EXECUTE msdb.dbo.sp_delete_backuphistory @dt
		EXECUTE msdb.dbo.sp_purge_jobhistory  @oldest_date=@dt;
		EXECUTE msdb..sp_maintplan_delete_log null,null,@dt;
		EXEC msdb..sysmail_delete_mailitems_sp @sent_before = @dt
		EXEC msdb..sysmail_delete_log_sp @logged_before = @dt', 
		@database_name=N'DBA', 
		@flags=0
        
EXEC  msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'W_DBA_Cleanup', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=2, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20200205, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959

EXEC  msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'

COMMIT TRANSACTION
GO

