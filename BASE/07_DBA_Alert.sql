
USE [msdb]
GO
IF(EXISTS(select name from msdb.dbo.sysjobs where name ='DBA_Alert'))
EXEC msdb.dbo.sp_delete_job @job_name=N'DBA_Alert', @delete_unused_schedule=1

BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA_Alert', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [diff_bck_alert]    Script Date: 17/06/2024 10:56:28 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'diff_bck_alert', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'IF EXISTS(select 1 from (SELECT TOP 1 percentage_variable,avg_duration 
		FROM dba_hist_diff_bck where job_name=''DBA_FULL_Backup'' order by rundatetime desc) c
		where percentage_variable >= (select valor from t_parametros where keyid=60) 
		and avg_duration >= (select valor2 from t_parametros where keyid=60))
BEGIN
     RAISERROR (''Backup much SLOWER than before!'', 14, 1) 
END
IF EXISTS(select 1 from (SELECT TOP 1 percentage_variable,avg_duration 
		FROM dba_hist_diff_bck where job_name=''DBA_FULL_Backup'' order by rundatetime desc) c
		where percentage_variable <= (select valor*(-1) from t_parametros where keyid=60) 
		and avg_duration >= (select valor2 from t_parametros where keyid=60))
BEGIN
     RAISERROR (''Backup much FASTER than before!'', 14, 1) 
END', 
		@database_name=N'DBA', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [diff_dbcc_alert]    Script Date: 17/06/2024 10:56:28 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'diff_dbcc_alert', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'IF EXISTS(select 1 from (SELECT TOP 1 percentage_variable,avg_duration 
		FROM dba_hist_diff_bck where job_name=''DBA_Database_Integrity_Check'' order by rundatetime desc) c
		where percentage_variable >= (select valor from t_parametros where keyid=61) 
		and avg_duration >= (select valor2 from t_parametros where keyid=61))
BEGIN
     RAISERROR (''Integrity much SLOWER than before!'', 14, 1) 
END
ELSE
IF EXISTS(select 1 from (SELECT TOP 1 percentage_variable,avg_duration 
		FROM dba_hist_diff_bck where job_name=''DBA_Database_Integrity_Check'' order by rundatetime desc) c
		where percentage_variable <= (select valor*(-1) from t_parametros where keyid=61) 
		and avg_duration >= (select valor2 from t_parametros where keyid=61))
BEGIN
     RAISERROR (''Integrity much FASTER than before!'', 14, 1) 
END', 
		@database_name=N'DBA', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Every_6h', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=6, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20240617, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO



