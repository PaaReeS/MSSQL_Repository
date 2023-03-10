/****** Object:  StoredProcedure [dbo].[proc_autogrow]    Script Date: 15/10/2019 15:23:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[proc_autogrow] with encryption
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @filename NVARCHAR(1000);
	DECLARE @bc INT;
	DECLARE @ec INT;
	DECLARE @bfn VARCHAR(1000);
	DECLARE @efn VARCHAR(10);
	 
	-- Get the name of the current default trace
	SELECT @filename = CAST(value AS NVARCHAR(1000))
	FROM ::fn_trace_getinfo(DEFAULT)
	WHERE traceid = 1 AND property = 2;
	 
	-- rip apart file name into pieces
	SET @filename = REVERSE(@filename);
	SET @bc = CHARINDEX('.',@filename);
	SET @ec = CHARINDEX('_',@filename)+1;
	SET @efn = REVERSE(SUBSTRING(@filename,1,@bc));
	SET @bfn = REVERSE(SUBSTRING(@filename,@ec,LEN(@filename)));
	 
	-- set filename without rollover number
	SET @filename = @bfn + @efn
	 
	-- process all trace files
	insert into [t_his_auto_grow_log] (start_time, event_name, db_name , file_name , growth_mb , ms)
	SELECT 
	  ftg.StartTime
	,cast(te.name as nvarchar(20)) AS EventName
	,cast(DB_NAME(ftg.databaseid) as nvarchar(30)) AS DatabaseName  
	,cast(ftg.Filename as nvarchar(30))  as Filename
	,cast(cast((ftg.IntegerData*8.00)/1024.00  as decimal(10,2)) as nvarchar(10)) AS GrowthMB 
	,cast((ftg.duration/1000) as nvarchar(10)) AS DurMS
	FROM ::fn_trace_gettable(@filename, DEFAULT) AS ftg 
	INNER JOIN sys.trace_events AS te ON ftg.EventClass = te.trace_event_id  
	WHERE (ftg.EventClass = 92  -- Date File Auto-grow
		OR ftg.EventClass = 93) -- Log File Auto-grow
	AND ftg.StartTime > (select isnull(max(start_time),0) from t_his_auto_grow_log)
	ORDER BY ftg.StartTime

END
GO
