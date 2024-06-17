create procedure proc_hist_diff
 with encryption
as
begin
SET NOCOUNT ON
declare @AVG_Duration int
declare @v_month integer
declare @v_year integer
select @v_month = case when month(getdate())=1 then 12 else month(getdate())-1 end , @v_year = case when month(getdate())=1 then year(getdate())-1 else year(getdate()) end

-------------------------------------------- BACKUP --------------------------------------------
if ((select COUNT(1) from dba_hist_diff where job_name ='DBA_FULL_Backup') = 0)
	insert into dba_hist_diff
	select  
	RunDateTime
	, step_name
	, rundurationminutes
	,null
	,null
	from(
		select
		msdb.dbo.agent_datetime(run_date, run_time) as 'RunDateTime'
		, step_name
		, ((run_duration/10000*3600 + (run_duration/100)%100*60 + run_duration%100 + 31 ) / 60) as 'rundurationminutes' 
		From msdb.dbo.sysjobhistory h 
		where step_name='DBA_FULL_Backup'
		and year(msdb.dbo.agent_datetime(run_date, run_time))= @v_year
		and month(msdb.dbo.agent_datetime(run_date, run_time))=@v_month) z	
		

/*Definimos @AVG_Duration, pendiente decidir si desde tabla con medias o se calcula cada vez*/
select @AVG_Duration=isnull(nullif(nullif(sum(rundurationminutes),0)/count(1),0) ,1)
From dba_hist_diff
where year(rundatetime)= @v_year
and month(rundatetime)= @v_month
and job_name ='DBA_FULL_Backup'

/*Calculamos diferencia respecto a la media de los ultimo X dias*/
insert into dba_hist_diff
select  
RunDateTime
, step_name
, rundurationminutes
, AVG_Duration
,cast((rundurationminutes - AVG_Duration)*100.0/AVG_Duration as numeric(10,2)) as Perc_Var
from(
	select 
	msdb.dbo.agent_datetime(run_date, run_time) as 'RunDateTime'
	, step_name
	, ((run_duration/10000*3600 + (run_duration/100)%100*60 + run_duration%100 + 31 ) / 60) as 'rundurationminutes' 
	, @AVG_Duration as AVG_Duration
	From msdb.dbo.sysjobhistory h 
	where step_name='DBA_FULL_Backup'
	and msdb.dbo.agent_datetime(run_date, run_time) not in (select rundatetime from dba_hist_diff  where job_name ='DBA_FULL_Backup')
	) z
---------------------------------------------------------------------------------------------------
-------------------------------------------- Integrity --------------------------------------------

if ((select COUNT(1) from dba_hist_diff where job_name ='DBA_Database_Integrity_Check') = 0)
	insert into dba_hist_diff
	select  
	RunDateTime
	, step_name
	, rundurationminutes
	,null
	,null
	from(
		select
		msdb.dbo.agent_datetime(run_date, run_time) as 'RunDateTime'
		, step_name
		, ((run_duration/10000*3600 + (run_duration/100)%100*60 + run_duration%100 + 31 ) / 60) as 'rundurationminutes' 
		From msdb.dbo.sysjobhistory h 
		where step_name='DBA_Database_Integrity_Check'
		and year(msdb.dbo.agent_datetime(run_date, run_time))= @v_year
		and month(msdb.dbo.agent_datetime(run_date, run_time))=@v_month) z	
		

/*Definimos @AVG_Duration, pendiente decidir si desde tabla con medias o se calcula cada vez*/
select @AVG_Duration=isnull(nullif(nullif(sum(rundurationminutes),0)/count(1),0) ,1)
From dba_hist_diff
where year(rundatetime)= @v_year
and month(rundatetime)= @v_month
and job_name ='DBA_Database_Integrity_Check'

/*Calculamos diferencia respecto a la media de los ultimo X dias*/
insert into dba_hist_diff
select  
RunDateTime
, step_name
, rundurationminutes
, AVG_Duration
,cast((rundurationminutes - AVG_Duration)*100.0/AVG_Duration as numeric(10,2)) as Perc_Var
from(
	select 
	msdb.dbo.agent_datetime(run_date, run_time) as 'RunDateTime'
	, step_name
	, ((run_duration/10000*3600 + (run_duration/100)%100*60 + run_duration%100 + 31 ) / 60) as 'rundurationminutes' 
	, @AVG_Duration as AVG_Duration
	From msdb.dbo.sysjobhistory h 
	where step_name='DBA_Database_Integrity_Check'
	and msdb.dbo.agent_datetime(run_date, run_time) not in (select rundatetime from dba_hist_diff where job_name ='DBA_Database_Integrity_Check')
	) z
----------------------------------------------------------------------------------------
end



