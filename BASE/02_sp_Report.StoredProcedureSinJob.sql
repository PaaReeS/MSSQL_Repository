
CREATE PROCEDURE [dbo].[sp_report2](  
  @MailProfile nvarchar(200) = NULL,   
  @MailID nvarchar(2000) = NULL,  
  @Server nvarchar(100) = NULL)  
AS
BEGIN  
	SET NOCOUNT ON;  
	SET ARITHABORT ON;  
	declare @v_month integer
	declare @v_year integer
	declare @v_max_snap_id integer
	declare @v_min_snap_id integer
	select @v_month = case when month(getdate())=1 then 12 else month(getdate())-1 end , @v_year = case when month(getdate())=1 then year(getdate())-1 else year(getdate()) end
	select @v_max_snap_id = max(snap_id) , @v_min_snap_id = min(snap_id) from dba_hist_snapshot where month(end_interval_time) = @v_month and year(end_interval_time) = @v_year
	declare @sqlstatement nvarchar(4000)
	DECLARE @SERVERNAME nvarchar(100);  
	SET @SERVERNAME = ISNULL(@Server,@@SERVERNAME);  

/****************** SizeTable *****************/  
CREATE TABLE #SizeTable (                                
	type  nvarchar(4)
	, db_name  nvarchar(100)
	, Size_MB  nvarchar(100)
	, Size_Growth nvarchar(100)                               
	)    
set @sqlstatement = 'select
Max_snap.type
, Max_snap.db_name
, Max_snap.Size_MB 
, Max_snap.Size_MB -  Min_snap.Size_MB as Size_Growth_MB
from(
	select 
	snap_id
	, case 
		when type=0 then ''ROW''
		when type=1 then ''LOG''
		else ''ERROR''
	end as type
	, database_id
	, db_name(database_id) as db_name
	, cast(size_on_disk_bytes/1024.00/1024.00  as numeric(30,2)) as Size_MB
	from dba_hist_dm_io_virtual_file_stats
	where snap_id='+ cast(@v_max_snap_id as nvarchar) +'	
	) Max_snap
	left join
	(
	select 
	snap_id
	, case 
		when type=0 then ''ROW''
		when type=1 then ''LOG''
		else ''ERROR''
	end as type
	, database_id
	, db_name(database_id) as db_name
	, cast(size_on_disk_bytes/1024.00/1024.00  as numeric(30,2)) as Size_MB
	from dba_hist_dm_io_virtual_file_stats
	where snap_id='+ cast(@v_min_snap_id as nvarchar) +'	
	) Min_snap
	on (Max_snap.type = Min_snap.type and Max_snap.database_id=Min_snap.database_id)
	where Max_snap.database_id > 4
	and Max_snap.Size_MB -  Min_snap.Size_MB > 0 
	order by 2 asc,1 desc'
insert into #SizeTable exec sp_executesql @sqlstatement
--20210422 Añadido and > 0 en select

/****************** Estado de los Discos ********************/  
CREATE TABLE #Discos (                                
	Drive nvarchar(5)                                
	, TotalSpace float
	, Drive_Free_Space float
	, PCTFree float
	)                        
Insert into #Discos
SELECT 
Drive
, TotalSpaceGB
, FreeSpaceGB
, PctFree
FROM(
	SELECT DISTINCT
	SUBSTRING(dovs.volume_mount_point, 1, 10) AS Drive
	, CONVERT(INT, dovs.total_bytes / 1024.0 / 1024.0 / 1024.0) AS TotalSpaceGB
	, CONVERT(INT, dovs.available_bytes / 1048576.0) / 1024 AS FreeSpaceGB
	, ROUND(( CONVERT(FLOAT, dovs.available_bytes / 1048576.0) / CONVERT(FLOAT, dovs.total_bytes /1024.0/1024.0) * 100 ), 2)  AS PctFree
	FROM sys.master_files AS mf
	CROSS APPLY sys.dm_os_volume_stats(mf.database_id, mf.file_id) AS dovs
	) AS DE

/****************** Jobs Failed *************/  
  
/************* Memoria ******************/  
CREATE TABLE #MemoryTable (
	Date nvarchar(25) 
	, Media nvarchar(10) 
	, Picos nvarchar(10) 
	, MaxMemory nvarchar(10), 
	)
INSERT INTO #MemoryTable select
cast(InicioSemana as nvarchar(10))+' - '+cast(FinSemana as nvarchar(10)) as Semana
, media
, Picos
, MaxMemory
from(
	select
	week
	, round(sum(Percentage_used)/cast(count(1) as float),0) as media
	, sum(Picos) as Picos
	, max(Percentage_used)  as MaxMemory
	, min(date) as InicioSemana
	, Max(date) as FinSemana
	from(
		select
		Max_snap.date
		, Max_snap.Percentage_used as Percentage_used
		, case when Max_snap.Percentage_used > 95.0 then 1 else 0 end as Picos
		,datepart(week,Max_snap.date) as week
		from(
			select 
			cast(s.end_interval_time as date) as date
			, cast(100 - (100 * CAST(dm.available_physical_memory_kb AS DECIMAL(18,3))/CAST(dm.total_physical_memory_kb AS DECIMAL(18,3)))as decimal(10,2))   as Percentage_used
			from dba_hist_dm_os_sys_memory dm
				join dba_hist_snapshot s on dm.snap_id=s.snap_id
			where month(s.end_interval_time) = @v_month
			and year(s.end_interval_time) = @v_year
			) Max_snap
			group by date,Percentage_used
		) a
	group by week
	) b
order by week asc
 
/************* SQL Server CPU Usage Details ******************/  
Create table #CPU(
	date nvarchar(25)
	, SqLServer_CPU_Utilization int
	, System_Idle int
	, Other_Process_CPU_Utilization int
	, Maximo int
	, max_90Percent_times int
	)      

insert into #CPU  
select
cast(InicioSemana as nvarchar(10))+' - '+cast(FinSemana as nvarchar(10)) as Semana
, SqLServer_CPU_Utilization
, System_Idle
, Other_Process_CPU_Utilization
, Maximo
, max_90Percent_times
from(
	select 
	week
	, round(sum(SQLServer_CPU_Utilization)/cast(COUNT(1) as float) ,0) as SqLServer_CPU_Utilization
	, round(sum(System_Idle)/cast(COUNT(1) as float) ,0) as System_Idle
	, round(sum(Other_Process_CPU_Utilization)/cast(COUNT(1) as float), 0) as Other_Process_CPU_Utilization
	, max(SQLServer_CPU_Utilization) as Maximo
	, sum(picos) as max_90Percent_times
	, min(v_end_interval_time) as InicioSemana
	, Max(v_end_interval_time) as FinSemana
	from(
		select 
		cast(Event_Time as date )as v_end_interval_time
		, datepart(week,Event_Time) as week
		, SQLServer_CPU_Utilization
		, System_Idle
		, Other_Process_CPU_Utilization
		, case when SQLServer_CPU_Utilization > 90 then 1 else 0 end as picos
	
		from dba_hist_cpu
		where month(Event_Time) = @v_month
		and year(Event_Time) = @v_year
		) as x
		group by week
	) as b
order by week asc

/****************** HTML Preparation *************************/  
  
DECLARE @TableHTML  nvarchar(MAX),                                    
  @strSubject nvarchar(100),                                    
  @OriServer nvarchar(100),                                
  @Version nvarchar(250),                                
  @Edition nvarchar(100),                                
  @ISClustered nvarchar(100),                                
  @SP nvarchar(100),                                
  @ServerCollation nvarchar(100),                                
  @SingleUser nvarchar(5),                                
  @LicenseType nvarchar(100),                                
  @Cnt int,           
  @URL nvarchar(1000),                                
  @Str nvarchar(1000),                                
  @NoofCriErrors nvarchar(3)       
 
-- Variable Assignment              
SELECT @Version = @@version                                
SELECT @Edition = CONVERT(nvarchar(100), serverproperty('Edition'))                                
SET @Cnt = 0                                
IF serverproperty('IsClustered') = 0                                 
BEGIN                                
	SELECT @ISClustered = 'No'                                
END                                
ELSE        
BEGIN                                
	SELECT @ISClustered = 'YES'                                
END                                
SELECT @SP = CONVERT(nvarchar(100), SERVERPROPERTY ('productlevel'))                                
SELECT @ServerCollation = CONVERT(nvarchar(100), SERVERPROPERTY ('Collation'))                                 
SELECT @LicenseType = CONVERT(nvarchar(100), SERVERPROPERTY ('LicenseType'))                                 
SELECT @SingleUser = CASE SERVERPROPERTY ('IsSingleUser')                                
      WHEN 1 THEN 'Yes'                                
      WHEN 0 THEN 'No'                                
      ELSE                                
      'null' END                                
SELECT @OriServer = CONVERT(nvarchar(50), SERVERPROPERTY('servername'))                                  
SELECT @strSubject = 'Informe Mensual ('+ CONVERT(nvarchar(100), @SERVERNAME) + ')'                                    
  
SET @TableHTML = ''  
SET @TableHTML = @TableHTML + '<div><font face="Verdana" size="6" color="#008C95"><H2><bold>'+ @SERVERNAME +'</bold></H2></font></div>'                                
/****** Tamaño BBDD ****/  
IF((select count (1) FROM #SizeTable) = 0)  
	SELECT  @TableHTML = @TableHTML +  '<font face="Verdana" size="4" color="#008C95"><H3><bold>No hay crecimientos en las Bases de Datos</bold></H3></font>'
else
begin
	SELECT                                   
	@TableHTML = @TableHTML +                                                
	'<font face="Verdana" size="4" color="#008C95"><H3><bold>Crecimientos de Bases de Datos</bold></H3></font><table style="BORDER-COLLAPSE: collapse" borderColor="#111111" cellPadding="0" width="100%" bgColor="#ffffff" borderColorLight="#000000" border="2">
	<tr>
	<th align="Center" width="50" bgColor="#008C95">
	<font face="Verdana" size="1" color="#FFFFFF">Tipo</font></th>
	<th align="Center" width="30" bgColor="#008C95">
	<font face="Verdana" size="1" color="#FFFFFF">Base de Datos</font></th>
	<th align="Center" width="120" bgColor="#008C95">
	<font face="Verdana" size="1" color="#FFFFFF">Tama&#241;o Base de Datos en MB</font></th>
	<th align="Center" width="120" bgColor="#008C95">
	<font face="Verdana" size="1" color="#FFFFFF">Tama&#241;o Crecido este mes en MB</font></th>                        
	</tr>'             
	SELECT                                   
	@TableHTML =  @TableHTML +                                 
	'<tr>    
	<td align="Center" ><font face="Verdana" size="1">' + ISNULL(CONVERT(nvarchar(100), type ), '')  +'</font></td>' +                                        
	'<td align="Center" ><font face="Verdana" size="1">' + ISNULL(CONVERT(nvarchar(100), db_name ), '')  +'</font></td>' +                                        
	'<td align="Center" ><font face="Verdana" size="1">' + ISNULL(CONVERT(nvarchar(100), Size_MB ), '')  +'</font></td>' +                                   
	'<td align="Center" ><font face="Verdana" size="1">' + ISNULL(CONVERT(nvarchar(100), Size_Growth ), '0')  +'</font></td>' +                                        
	'</tr>'                       
FROM #SizeTable  
end
/****** Estado Discos ****/  
SELECT                                   
@TableHTML = @TableHTML +                                     
'</table>                                  
<p style="margin-top: 1; margin-bottom: 0">&nbsp;</p>                                  
<font face="Verdana" size="4" color="#008C95"><H3><bold>Estado de los Discos</bold></H3></font>                                  
<table style="BORDER-COLLAPSE: collapse" borderColor="#111111" cellPadding="0" width="100%" bgColor="#ffffff" borderColorLight="#000000" border="2">                                      
<tr>                                      
<th align="Center" width="50" bgColor="#008C95">                                      
<font face="Verdana" size="1" color="#FFFFFF">Disco</font></th>                                      
<th align="Center" width="120" bgColor="#008C95">                                   
<font face="Verdana" size="1" color="#FFFFFF">Tama&#241;o Disco en GB</font></th>    
<th align="Center" width="120" bgColor="#008C95">                                   
<font face="Verdana" size="1" color="#FFFFFF">Espacio Libre en GB</font></th>   
<th align="Center" width="120" bgColor="#008C95">                                   
<font face="Verdana" size="1" color="#FFFFFF">Porcentaje Libre</font></th>     
</tr>'
SELECT                                   
@TableHTML =  @TableHTML +                                       
'<tr>
<td align="Center"><font face="Verdana" size="1">' + ISNULL(CONVERT(VARCHAR(100), Drive ), '') +'</font></td>' +                                        
'<td align="Center"><font face="Verdana" size="1">' + ISNULL(CONVERT(VARCHAR(100), TotalSpace ), '') +'</font></td>' + 
CASE 
	WHEN PCTFree < 20 THEN '<td align="Center"><font face="Verdana" size="1" color="#FF0000"><b>' + ISNULL(CONVERT(VARCHAR(100),  Drive_Free_Space ), '')  +'</font></td>' 
ELSE 
	'<td align="Center"><font face="Verdana" size="1" color="#40C211"><b>' + ISNULL(CONVERT(VARCHAR(100),  Drive_Free_Space), '')  +'</font></td>' 
END 
+ '<td align="Center"><font face="Verdana" size="1">' + ISNULL(CONVERT(VARCHAR(100),  PCTFree ), '')  +'</font></td>
</tr>'            
FROM #Discos 

/***** Memoria ****/  
SELECT                                   
@TableHTML =  @TableHTML +                              
'</table>                                  
<p style="margin-top: 1; margin-bottom: 0">&nbsp;</p>                                  
<font face="Verdana" size="4" color="#008C95"><H3><bold>Memoria y CPU</bold></H3></font><table id="AutoNumber1" style="BORDER-COLLAPSE: collapse" borderColor="#111111" height="40" cellSpacing="0" cellPadding="0" width="100%" border="2">                                  
<tr>                
<th align="Center"  bgColor="#008C95"><font face="Verdana" size="1" color="#FFFFFF">Semana</font></th>                              
<th align="Center"  bgColor="#008C95"><font face="Verdana" size="1" color="#FFFFFF">Porcentaje de Memoria Usado</font></th>    
<th align="Center"  bgColor="#008C95"><font face="Verdana" size="1" color="#FFFFFF">Picos de Memoria</font></th>      
<th align="Center"  bgColor="#008C95"><font face="Verdana" size="1" color="#FFFFFF">Memoria m&#225;xima utilizada</font></th>    
<th align="Center"  bgColor="#008C95"><font face="Verdana" size="1" color="#FFFFFF">CPU utilizada por el SQL Server</font></th>    
<th align="Center"  bgColor="#008C95"><font face="Verdana" size="1" color="#FFFFFF">CPU Libre</font></th>      
<th align="Center"  bgColor="#008C95"><font face="Verdana" size="1" color="#FFFFFF">CPU no utilizada por el SQL Server</font></th>   
<th align="Center"  bgColor="#008C95"><font face="Verdana" size="1" color="#FFFFFF">M&#225;ximo de CPU del Servidor</font></th>  
<th align="Center"  bgColor="#008C95"><font face="Verdana" size="1" color="#FFFFFF">Picos de CPU</font></th>  
</tr>'                                  
SELECT      
@TableHTML =  @TableHTML +                                       
'<tr>                                    
<td align="Center"><font face="Verdana" size="1">' + ISNULL(CONVERT(nvarchar(25),  m.Date ), '')  +'</font></td>' +
CASE
	WHEN Media < 95 THEN '<td align="Center"><font face="Verdana" size="1" color="#40C211"><b>' + ISNULL(CONVERT(nvarchar(100),  Media), '') +'</font></td>' 
ELSE 
	'<td align="Center"><font face="Verdana" size="1" color="#FF0000"><b>' + ISNULL(CONVERT(nvarchar(100),  Media), '')  +'</font></td>'  
END 
+'<td align="Center"><font face="Verdana" size="1">'+ISNULL(CONVERT(nvarchar(2000),Picos ),'')+' </font></td>
<td align="Center"><font face="Verdana" size="1">'+ISNULL(CONVERT(nvarchar(2000),MaxMemory ),'')+' </font></td>  
<td align="Center"><font face="Verdana" size="1">' + ISNULL(CONVERT(nvarchar(100),  SqLServer_CPU_Utilization ), '')  +'</font></td>
<td align="Center"><font face="Verdana" size="1">' + ISNULL(CONVERT(nvarchar(100),  System_Idle ), '')  +'</font></td>
<td align="Center"><font face="Verdana" size="1">' + ISNULL(CONVERT(nvarchar(100),  Other_Process_CPU_Utilization ), '')  +'</font></td>
<td align="Center"><font face="Verdana" size="1">' + ISNULL(CONVERT(nvarchar(100),  Maximo ), '')  +'</font></td>
<td align="Center"><font face="Verdana" size="1">' + ISNULL(CONVERT(nvarchar(100),  max_90Percent_times ), '')  +'</font></td>
</tr>' 
FROM #MemoryTable m 
	LEFT JOIN #CPU c 
		on (m.Date=c.date)
/****** End to HTML Formatting  ***/    
SELECT                              
@TableHTML =  @TableHTML + '</table><p style="margin-top: 0; margin-bottom: 0">&nbsp;</p><p>&nbsp;</p>'    

IF (@MailProfile IS NOT NULL AND @MailID IS NOT NULL)
BEGIN
	EXEC msdb.dbo.sp_send_dbmail 
		 @profile_name = @MailProfile, 
		 @recipients = @MailID, 
		 @subject = @strSubject, 
		 @body = @TableHTML, 
		 @body_format = 'HTML';
END

SELECT @TableHTML "HC_Report";  
  
DROP TABLE  #Discos  
DROP TABLE	#MemoryTable;
DROP TABLE  #SizeTable 


SET NOCOUNT OFF;  
SET ARITHABORT OFF;  
END 

