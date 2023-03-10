/****** Object:  StoredProcedure [dbo].[proc_awr_cpu_hour]    Script Date: 15/10/2019 15:23:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE procedure [dbo].[proc_awr_cpu_hour](@p_begin_snap int)  with encryption
as
begin
	SET NOCOUNT ON

	DECLARE @t_tabla_orden TABLE (
	snap_id integer
	, pos integer
	, pos2 integer
	, texto nvarchar(10)
	, datos nvarchar(60)
	) 
		
    declare @q_snap_id integer
	declare @q_end_interval_time datetime
	declare @q_Event_time varchar(20)
	declare @q_SqLServer_CPU_Utilization int
	declare @q_System_Idle int
	declare @q_Other_Process_CPU_Utilization int
	declare @max int
	declare	@pos integer
	declare @sqlstatement nvarchar(MAX)
	declare @sqlstatement2 nvarchar(MAX)
	declare @sqlstatement3 nvarchar(MAX)
	declare @v_snap_id integer
	declare @v_end_interval_time nvarchar(20)
	
	if not exists (select snap_id from dba_hist_snapshot where snap_id = @p_begin_snap)
	begin
		print('Snapshot no existente. Ten más ojo. Saliendo...')
		return
	end	
	 if ((select end_interval_time from dba_hist_snapshot where snap_id = @p_begin_snap)< (select getdate()-15))
	begin
		print('No tenemos información tan detallada anterior a 15 dias. Haberlo mirado antes...')
		return
	end	
	set @v_end_interval_time = (select  CONVERT(VARCHAR(10), end_interval_time, 103)+ ' ' + CONVERT(VARCHAR(5), end_interval_time, 108) from dba_hist_snapshot	where snap_id = @p_begin_snap)
	set @sqlstatement =	'DECLARE c_snap_query CURSOR FOR
			select * from(
				select
				CONVERT(VARCHAR(10), Event_time, 103)+ '' '' + CONVERT(VARCHAR(2), Event_time, 108)+'':00'' as v_end_interval_time
				, Event_time
				, ROW_NUMBER() over (order by event_time asc) AS Pos
				, SQLServer_CPU_Utilization
				, System_Idle
				, Other_Process_CPU_Utilization
				from dba_hist_cpu) as x
				where v_end_interval_time = '''+ cast(@v_end_interval_time as varchar) +''' 
				order by Event_time asc'		
		exec sp_executesql @sqlstatement
		open c_snap_query
		Fetch next from c_snap_query into @q_end_interval_time, @q_Event_time, @q_snap_id, @q_SqLServer_CPU_Utilization, @q_System_Idle, @q_Other_Process_CPU_Utilization
		
		set @pos = 0
		set @sqlstatement3=N'select t1.texto as [MINUTE], cast(t1.datos as nvarchar(2))  as ['+ cast(@pos as varchar(2))+']'
		set @sqlstatement2=N'
		from(
			select 
			ROW_NUMBER() over(order by snap_id desc) u
			, texto
			, Datos
			from #t_tabla_orden
			where snap_id = '+ cast(@q_snap_id as varchar) +'
		) t1
		' 
		
		WHILE @@FETCH_STATUS = 0  
		BEGIN
			insert into @t_tabla_orden (snap_id, pos, pos2, texto, Datos) values (@q_snap_id, @pos, 1,'SQLS USED', @q_SqLServer_CPU_Utilization);
			insert into @t_tabla_orden (snap_id, pos, pos2, texto, Datos) values (@q_snap_id, @pos, 2,'SYS IDLE', @q_System_Idle);
			insert into @t_tabla_orden (snap_id, pos, pos2, texto, Datos) values (@q_snap_id, @pos, 3,'OTHER', @q_Other_Process_CPU_Utilization);
			--insert into @t_tabla_orden (snap_id, pos, pos2, texto, Datos) values (@q_snap_id, @pos, 4,'event_time', @q_Event_time); --para comprobar orden
					
			set @pos = @pos + 1
		
			Fetch next from c_snap_query into @q_end_interval_time, @q_Event_time, @q_snap_id, @q_SqLServer_CPU_Utilization, @q_System_Idle, @q_Other_Process_CPU_Utilization
			IF @@FETCH_STATUS = -1 BREAK;
			set @sqlstatement3=@sqlstatement3 + N', cast(t'+ cast(@q_snap_id as varchar) +'.datos as nvarchar(2)) as ['+ cast(@pos as varchar(2))+']'
			set @sqlstatement2=@sqlstatement2 + N'
			join(
				select 
				ROW_NUMBER() over(order by snap_id desc) u
				, Datos
				from #t_tabla_orden
				where snap_id = '+ cast(@q_snap_id as varchar) +'
				) t'+ cast(@q_snap_id as varchar) +'
				on t1.u=t'+ cast(@q_snap_id as varchar) +'.u'
		END
				
		CLOSE c_snap_query
		DEALLOCATE c_snap_query
		
	select * into #t_tabla_orden from @t_tabla_orden
	set @sqlstatement2=@sqlstatement3+@sqlstatement2
	EXEC sp_executesql @sqlstatement2
end
GO
