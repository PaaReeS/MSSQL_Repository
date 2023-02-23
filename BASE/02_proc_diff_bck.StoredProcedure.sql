/* guardar diario info detallada x 6 meses
 Despues hacer medias con año/mes/01
 Comparamos medias de tiempo totales del mes.
*/
create procedure proc_dif_bck with encryption
as
begin
SET NOCOUNT ON
declare @AVG_Duration int
declare @v_month integer
declare @v_year integer
select @v_month = case when month(getdate())=1 then 12 else month(getdate())-1 end , @v_year = case when month(getdate())=1 then year(getdate())-1 else year(getdate()) end

if ((select COUNT(1) from dba_hist_dif_bck) = 0)
	insert into dba_hist_dif_bck
	select  
	RunDateTime
	, step_name
	, RunDurationMinutes
	,null
	,null
	from(
		select
		msdb.dbo.agent_datetime(run_date, run_time) as 'RunDateTime'
		, step_name
		, ((run_duration/10000*3600 + (run_duration/100)%100*60 + run_duration%100 + 31 ) / 60) as 'RunDurationMinutes' 
		From msdb.dbo.sysjobhistory h 
		where step_name='FULL_Backup'
		and year(msdb.dbo.agent_datetime(run_date, run_time))= @v_year
		and month(msdb.dbo.agent_datetime(run_date, run_time))=@v_month) z	
		

/*Definimos @AVG_Duration, pendiente decidir si desde tabla con medias o se calcula cada vez*/
select @AVG_Duration=isnull(nullif(nullif(sum(RunDurationMinutes),0)/count(1),0) ,1)
From dba_hist_dif_bck
where year(rundatetime)= @v_year
and month(rundatetime)= @v_month

/*Calculamos diferencia respecto a la media de los ultimo X dias*/
insert into dba_hist_dif_bck
select  
RunDateTime
, step_name
, RunDurationMinutes
, AVG_Duration
,cast((RunDurationMinutes - AVG_Duration)*100.0/AVG_Duration as numeric(10,2)) as Perc_Var
from(
	select 
	msdb.dbo.agent_datetime(run_date, run_time) as 'RunDateTime'
	, step_name
	, ((run_duration/10000*3600 + (run_duration/100)%100*60 + run_duration%100 + 31 ) / 60) as 'RunDurationMinutes' 
	, @AVG_Duration as AVG_Duration
	From msdb.dbo.sysjobhistory h 
	where step_name='FULL_Backup'
	and msdb.dbo.agent_datetime(run_date, run_time) not in (select rundatetime from dba_hist_dif_bck)
	) z

end










/*
WITH Backups AS (SELECT bs.database_name, bs.database_guid, bs.type AS backup_type,backup_start_date 
 , MBpsAvg = CAST(AVG(( bs.backup_size / ( CASE WHEN DATEDIFF(ss, bs.backup_start_date, bs.backup_finish_date) = 0 THEN 1 ELSE DATEDIFF(ss, bs.backup_start_date, bs.backup_finish_date) END ) / 1048576 )) AS INT) 
 , MBpsMin = CAST(MIN(( bs.backup_size / ( CASE WHEN DATEDIFF(ss, bs.backup_start_date, bs.backup_finish_date) = 0 THEN 1 ELSE DATEDIFF(ss, bs.backup_start_date, bs.backup_finish_date) END ) / 1048576 )) AS INT) 
 , MBpsMax = CAST(MAX(( bs.backup_size / ( CASE WHEN DATEDIFF(ss, bs.backup_start_date, bs.backup_finish_date) = 0 THEN 1 ELSE DATEDIFF(ss, bs.backup_start_date, bs.backup_finish_date) END ) / 1048576 )) AS INT) 
 , SizeMBAvg = AVG(backup_size / 1048576.0) 
 , SizeMBMin = MIN(backup_size / 1048576.0) 
 , SizeMBMax = MAX(backup_size / 1048576.0) 
 , CompressedSizeMBAvg = AVG(compressed_backup_size / 1048576.0) 
 , CompressedSizeMBMin = MIN(compressed_backup_size / 1048576.0) 
 , CompressedSizeMBMax = MAX(compressed_backup_size / 1048576.0) 
 FROM [msdb].dbo.backupset bs 
 WHERE  bs.is_damaged = 0 
 and database_name='x3v12'
 and is_snapshot=0
 and type <> 'L'
 GROUP BY bs.database_name, bs.database_guid, bs.type,backup_start_date)
SELECT bF.database_name
,bF.backup_start_date
,bF.backup_type
 , bF.MBpsAvg AS MBpsAvg 
 , bF.MBpsMin AS MBpsMin 
 , bF.MBpsMax AS MBpsMax 
 , bF.SizeMBAvg AS SizeMBAvg 
 , bF.SizeMBMin AS SizeMBMin 
 , bF.SizeMBMax AS SizeMBMax 
 , bF.CompressedSizeMBAvg AS CompressedSizeMBAvg 
 , bF.CompressedSizeMBMin AS CompressedSizeMBMin 
 , bF.CompressedSizeMBMax AS CompressedSizeMBMax 
 
 FROM Backups bF 
 
 order by 2 desc; 

 */