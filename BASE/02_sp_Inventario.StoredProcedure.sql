Create procedure sp_Inventario with encryption as
Begin
	SET NOCOUNT ON
	declare @server nvarchar (100)
	declare @instance nvarchar (100)  
	declare @version nvarchar (100)  
	declare @edition nvarchar (100)  
	declare @sp nvarchar (100)  
	declare @max_memory nvarchar (100)  
	declare @collation nvarchar (100)  
	declare @clidatabases int
	declare @size varchar (100)
	declare @ip varchar (100)
	declare @port varchar (100)
	declare @entorno nvarchar (100)
	declare @clustered nvarchar (1)  
	declare @AG nvarchar (1)  
	declare @level nvarchar (100)  
	declare @InstanceDefaultBackupPath nvarchar (100)  
	declare @InstanceDefaultDataPath nvarchar (100)  
	declare @InstanceDefaultLogPath nvarchar (100)  
	--Mantenimiento 
	declare @bck_full_starttime nvarchar (5)  
	declare @bck_full_avgtime nvarchar (10)  
	declare @bck_log_interval nvarchar (5)
	declare @bck_local_retention nvarchar (10)
	declare @Integrity_starttime nvarchar (5)  
	declare @Integrity_avgtime nvarchar (10)  
	declare @IDX_starttime nvarchar (5)  
	declare @IDX_avgtime nvarchar (10)  
	--Servicio
	declare @MSSQLuser nvarchar(100)
	declare @MSSQLAgentuser nvarchar(100)
	declare @MSSQLServiceStart nvarchar(10)
	declare @SQLAgentServiceStart nvarchar(10)
	declare @SQLArg0 nvarchar (150)
	declare @SQLArg2 nvarchar (150)
	declare @temp TABLE (Trace nvarchar(MAX), status int, global int,session int)
	
    set @entorno = (select  case when CONVERT(VARCHAR(128),SERVERPROPERTY ('machinename')) like '%PRE%' then 'PRE'when CONVERT(VARCHAR(128),SERVERPROPERTY ('machinename')) like '%DES%' then 'DES' else 'PRO'end)
    set @server = (select CONVERT(VARCHAR(128), SERVERPROPERTY ('machinename')))
    set @instance = (select @@SERVICENAME) 
    set @version = (select left(@@version,25))
    set @edition = (CONVERT(VARCHAR(128),SERVERPROPERTY ('Edition')))
    set @sp = (CONVERT(VARCHAR(128),SERVERPROPERTY ('ProductLevel')))
    set @max_memory=(SELECT CONVERT(VARCHAR(128),value) FROM sys.configurations WHERE name = 'max server memory (MB)')
    set @collation = CONVERT(VARCHAR(128),SERVERPROPERTY('collation'))
    set @clidatabases = (select count(*) from sys.databases where database_id > 4)
    set @size=(select SUM(CONVERT(int,(size * 8.00) / 1024.00 / 1024.00 )) As UsedSpace from master.sys.master_files)
    set @clustered = (CASE WHEN CONVERT(VARCHAR(128),SERVERPROPERTY ('IsClustered'))  ='1' THEN 'Y' ELSE 'N'  END)
    set @AG = (CASE WHEN CONVERT(VARCHAR(128),SERVERPROPERTY ('IsHadrEnabled')) ='1' THEN 'S' ELSE 'N'  END)
    set @level = (CONVERT(VARCHAR(128),SERVERPROPERTY ('ProductUpdateLevel')))
    set @ip = (SELECT top 1 cast(local_net_address as varchar) FROM   sys.dm_exec_connections where client_net_address <> '127.0.0.1' and client_net_address <> '<local machine>')
    set @port = (SELECT DISTINCT local_tcp_port FROM sys.dm_exec_connections WHERE local_tcp_port IS NOT NULL )
	set @InstanceDefaultBackupPath = (select CONVERT(VARCHAR(128),SERVERPROPERTY ('InstanceDefaultBackupPath')))
	set @InstanceDefaultDataPath = (select CONVERT(VARCHAR(128),SERVERPROPERTY ('InstanceDefaultDataPath')))
	set @InstanceDefaultLogPath = (select CONVERT(VARCHAR(128),SERVERPROPERTY ('InstanceDefaultLogPath')))
	
	--Mantenimientos
	set @bck_full_starttime = (select left(right('00'+convert(nvarchar,ssch.active_start_time),6),2)+':'+substring(right('00'+convert(nvarchar,ssch.active_start_time),6),3,2) as inicio from msdb.dbo.sysjobs as sjob join msdb.dbo.sysjobschedules as sjobsch on sjob.job_id = sjobsch.job_id join msdb.dbo.sysschedules as ssch on sjobsch.schedule_id = ssch.schedule_id
							where sjob.name ='FULL_Backup')
	set @bck_full_avgtime = (select avg(((run_duration/10000 * 60 * 60) + (run_duration/100%100 * 60) + (run_duration%100 ))/60) From msdb.dbo.sysjobhistory where step_name = 'FULL_Backup' and run_date > convert(varchar,getdate()-7,112)) 
	set @bck_log_interval = (SELECT convert(nvarchar,freq_subday_interval) AS Intervalo FROM msdb.dbo.sysschedules where name ='Min_LOG_Backup')
	set @bck_local_retention = (select case when retfull=retlog then cast(retfull as nvarchar) else 'ERROR' end as Retencion from(
								select (SELECT substring(substring(sJSTP.command,CHARINDEX('CleanupTime',sJSTP.command)+13,10),1,CHARINDEX(',',substring(sJSTP.command,CHARINDEX('CleanupTime',sJSTP.command)+13,10),1)-1)
								FROM msdb.dbo.sysjobs AS sJOB LEFT JOIN msdb.dbo.sysjobsteps AS sJSTP ON sJOB.job_id = sJSTP.job_id AND sJOB.start_step_id = sJSTP.step_id where sJOB.name = 'FULL_Backup') as retfull
								,(SELECT substring(substring(sJSTP.command,CHARINDEX('CleanupTime',sJSTP.command)+13,10),1,CHARINDEX(',',substring(sJSTP.command,CHARINDEX('CleanupTime',sJSTP.command)+13,10),1)-1)
								FROM msdb.dbo.sysjobs AS sJOB LEFT JOIN msdb.dbo.sysjobsteps AS sJSTP ON sJOB.job_id = sJSTP.job_id AND sJOB.start_step_id = sJSTP.step_id where sJOB.name = 'Log_Backup') as retlog	) as a)
	set @Integrity_starttime = (select left(right('00'+convert(nvarchar,ssch.active_start_time),6),2)+':'+substring(right('00'+convert(nvarchar,ssch.active_start_time),6),3,2) as inicio from msdb.dbo.sysjobs as sjob join msdb.dbo.sysjobschedules as sjobsch on sjob.job_id = sjobsch.job_id join msdb.dbo.sysschedules as ssch on sjobsch.schedule_id = ssch.schedule_id
								where sjob.name ='Database_Integrity_Check')
	set @Integrity_avgtime = (select avg(((run_duration/10000 * 60 * 60) + (run_duration/100%100 * 60) + (run_duration%100 ))/60) From msdb.dbo.sysjobhistory where step_name = 'Database_Integrity_Check' and run_date > convert(varchar,getdate()-7,112)) 
	set @IDX_starttime = (select left(right('00'+convert(nvarchar,ssch.active_start_time),6),2)+':'+substring(right('00'+convert(nvarchar,ssch.active_start_time),6),3,2) as inicio from msdb.dbo.sysjobs as sjob join msdb.dbo.sysjobschedules as sjobsch on sjob.job_id = sjobsch.job_id join msdb.dbo.sysschedules as ssch on sjobsch.schedule_id = ssch.schedule_id
							where sjob.name ='Update_Index&statistics')
	set @IDX_avgtime = (select avg(((run_duration/10000 * 60 * 60) + (run_duration/100%100 * 60) + (run_duration%100 ))/60) From msdb.dbo.sysjobhistory where step_name = 'Update_Index&statistics' and run_date > convert(varchar,getdate()-7,112)) 
	--Servicio
	set @MSSQLuser = (select service_account from sys.dm_server_services where servicename like 'SQL Server (%')
	set @MSSQLAgentuser = (select service_account from sys.dm_server_services where servicename like '%Agent%')
	set @MSSQLServiceStart = (SELECT case when value_data=0 then 'Other'	when value_data=2 then 'Auto' when value_data=3 then 'Manual'	when value_data=4 then 'Disabled'	else 'Other' end FROM sys.dm_server_registry where value_name='Start' and registry_key like '%MSSQL%') 
	set @SQLAgentServiceStart = (SELECT case when value_data=0 then 'Other'	when value_data=2 then 'Auto' when value_data=3 then 'Manual'	when value_data=4 then 'Disabled'	else 'Other' end FROM sys.dm_server_registry where value_name='Start' and registry_key like '%Agent%') 
	
	select @SQLArg0  = SQLArg0, @SQLArg2 = SQLArg2 from(select (select substring(CONVERT(varchar(150), value_data),3,147) FROM sys.dm_server_registry where value_name like 'SQLArg0') as SQLArg0,(select substring(CONVERT(varchar(150), value_data),3,147) FROM sys.dm_server_registry where value_name like 'SQLArg2') as SQLArg2) as a	
	declare @trace nvarchar(max)

	insert into @temp exec ('dbcc tracestatus WITH NO_INFOMSGS')
	select @trace=coalesce(@trace+ ', ' + Trace,Trace) from @temp

	SELECT 
	  @server AS 'Servidor'
	, @instance AS 'Instancia'
	, @entorno AS 'Entorno'
	, @version AS 'Version'
	, @edition AS 'Edicion'
	, @sp AS 'ServicePack'
	, @level AS 'Nivel CU'
	, @max_memory AS 'Memoria'
	, @ip AS 'IP'
	, @port AS 'Puerto'
	, @collation AS 'Collation'
	, @clidatabases AS 'Numero bases de datos'
	, @size AS 'Total DBSize(Gb)'
	, @AG AS 'AlwaysOn'
	, @clustered AS 'Failover Cluster'
	, @MSSQLuser as 'Usuario Servicio'
	, @MSSQLServiceStart as 'SQL Start Mode'
	, @MSSQLAgentuser as 'Usuario Agente'
	, @SQLAgentServiceStart as 'Agent Start Mode'
	, @bck_full_starttime as 'Bck Full'
	, @Integrity_starttime as 'Integrity'
	, @IDX_starttime as 'IDX'
	, @bck_log_interval as 'Log'
	, @bck_local_retention as 'Retencion Local (h)'
	, @bck_full_avgtime as 'Bck Full AVG time (min)'
	, @Integrity_avgtime as 'Integrity AVG time (min)'
	, @IDX_avgtime as 'IDX AVG time (min)'
	, @InstanceDefaultDataPath as 'Ruta Datos'
	, @InstanceDefaultLogPath as 'Ruta Logs'
	, @InstanceDefaultBackupPath as 'Ruta Backup'
	, @SQLArg0 as 'Ruta Master Data'
	, @SQLArg2 as 'Ruta Master Log'
	, @trace as 'SqlArg3'

END
	
	


	
	
	
	
	
	