USE [msdb]
GO
IF(EXISTS(select name from msdb.dbo.sysjobs where name ='DBA_AWR'))
EXEC msdb.dbo.sp_delete_job @job_name=N'DBA_AWR', @delete_unused_schedule=1
GO
BEGIN TRANSACTION
DECLARE @jobId BINARY(16)
EXEC msdb.dbo.sp_add_job @job_name=N'DBA_AWR', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'Sothis_Agent', @job_id = @jobId OUTPUT


EXEC msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'DBA_AWR_SNAP', 
		@step_id=1, 
		@os_run_priority=0,
        @on_success_action=3,
        @on_fail_action=2,         
		@subsystem=N'TSQL', 
		@command=N'exec dbo.proc_awr_snap',
		@database_name=N'DBA' 
	
EXEC msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1

EXEC msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'DBA_AWR_AUTOGROW', 
		@step_id=2, 
		@os_run_priority=0, 
        @on_success_action=3,
        @on_fail_action=2,  
		@subsystem=N'TSQL', 
		@command=N'exec dbo.proc_autogrow
		exec dbo.proc_hist_diff', 
		@database_name=N'DBA', 
		@flags=0 

EXEC msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'DBA_AWR_CLEAN_HIS', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec dbo.proc_truncate_cpu_his;
		exec dbo.proc_truncate_awr;', 
		@database_name=N'DBA', 
		@flags=0


EXEC msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'H_DBA_AWR', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20190129, 
		@active_end_date=99991231 
		

EXEC msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
COMMIT TRANSACTION

GO
