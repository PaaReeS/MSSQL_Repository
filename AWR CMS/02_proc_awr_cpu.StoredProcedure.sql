/****** Object:  StoredProcedure [dbo].[proc_awr_cpu]    Script Date: 15/10/2019 15:23:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE [dbo].[proc_awr_cpu](@p_host nvarchar(50),@p_begin_snap int, @p_end_snap int)  with encryption
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
	DECLARE	@pos integer
	
	--Revisar
	declare @sqlstatement nvarchar(MAX)
	declare @sqlstatement2 nvarchar(MAX)
	declare @sqlstatement3 nvarchar(MAX)
	--
	declare @v_snap_id integer
	declare @v_end_interval_time nvarchar(20)
	
	/*COMPROBACIONES PREVIAS A EXEC*/
	set @sqlstatement='if not exists (select snap_id from ' + @p_host + '..dba_hist_snapshot where snap_id in ('+cast(@p_begin_snap as nvarchar) +', '+cast(@p_end_snap as nvarchar)+'))
	begin
		print(''Snapshots no existentes. Ten más ojo. Saliendo...'')
		return
	end	'
	exec sp_executesql @sqlstatement
	if(@p_end_snap - @p_begin_snap > 15)
	begin
		print('Te has pasado tronco. Demasiada información pides. Saliendo...')
		return
	end
	set @sqlstatement='
	if(@p_end_snap = (select max(snap_id) from ' + @p_host + '..dba_hist_snapshot))
	begin
		set @p_end_snap=@p_end_snap-1
	end'
	exec sp_executesql @sqlstatement,N'@p_end_snap int OUTPUT', @p_end_snap OUTPUT
	
	set @sqlstatement='declare c_snapshot cursor for
	select snap_id
	,CONVERT(VARCHAR(10), end_interval_time, 103)+ '' '' + CONVERT(VARCHAR(5), end_interval_time, 108)
	from ' + @p_host + '..dba_hist_snapshot
	where snap_id between '+cast(@p_begin_snap as nvarchar) +' and '+cast(@p_end_snap as nvarchar)+'
	order by snap_id'
	exec sp_executesql @sqlstatement

	open c_snapshot
	fetch next from c_snapshot into @v_snap_id, @v_end_interval_time	
	set @sqlstatement3=N'select t1.texto as [ ], cast(t1.datos as nvarchar(16))  as ['+ cast(@v_end_interval_time as varchar)+']'
	set @sqlstatement2=N'
		from(
			select 
			ROW_NUMBER() over(order by snap_id desc) u
			, texto
			, Datos
			from #t_tabla_orden
			where snap_id = '+ cast(@v_snap_id as varchar) +'
		) t1
		' 

	while 1=1  
	begin		
		set @sqlstatement =	'DECLARE c_snap_query CURSOR FOR
			select 
			v_end_interval_time
			, round( sum(SQLServer_CPU_Utilization)/cast(COUNT(1) as float) ,0) as round
			, round(sum(System_idle)/cast(COUNT(1) as float) ,0) as round2
			, round(sum(Other_Process_CPU_Utilization)/cast(COUNT(1) as float), 0) as round3
			,max(SQLServer_CPU_Utilization) as Max
			from(
				select 
				CONVERT(VARCHAR(10), Event_time, 103)+ '' '' + CONVERT(VARCHAR(2), Event_time, 108)+'':00'' as v_end_interval_time
				, SQLServer_CPU_Utilization
				, System_Idle
				, Other_Process_CPU_Utilization
				from  ' + @p_host + '..dba_hist_cpu) as x
				where v_end_interval_time = '''+ cast(@v_end_interval_time as varchar) +''' 
				group by v_end_interval_time'		
		exec sp_executesql @sqlstatement
		open c_snap_query
		Fetch next from c_snap_query into @q_Event_time, @q_SqLServer_CPU_Utilization, @q_System_Idle, @q_Other_Process_CPU_Utilization, @max
		
		set @pos = 1
		WHILE @@FETCH_STATUS = 0  
		BEGIN
			insert into @t_tabla_orden (snap_id, pos, pos2, texto, Datos) values (@v_snap_id, @pos, 1,'SQLS USED', @q_SqLServer_CPU_Utilization);
			insert into @t_tabla_orden (snap_id, pos, pos2, texto, Datos) values (@v_snap_id, @pos, 2,'SYS IDLE', @q_System_Idle);
			insert into @t_tabla_orden (snap_id, pos, pos2, texto, Datos) values (@v_snap_id, @pos, 3,'OTHER', @q_Other_Process_CPU_Utilization);
			insert into @t_tabla_orden (snap_id, pos, pos2, texto, Datos) values (@v_snap_id, @pos, 4,'MAX', @max);
			--insert into @t_tabla_orden (pos, pos2, texto, Datos) values (@pos, 4,'TIME', @q_Event_time);
			--insert into @t_tabla_orden (snap_id, pos, pos2, texto, Datos) values (@q_snap_id, @pos, 0, ' ', ' ');
			--insert into @t_tabla_orden (snap_id, pos, pos2, texto, Datos) values (@q_snap_id, @pos, 0, ' ', ' ');
			
			set @pos = @pos + 1
		
			Fetch next from c_snap_query into  @q_Event_time, @q_SqLServer_CPU_Utilization, @q_System_Idle, @q_Other_Process_CPU_Utilization, @max
		END
					
		CLOSE c_snap_query
		DEALLOCATE c_snap_query
		
		FETCH NEXT FROM c_snapshot INTO @v_snap_id, @v_end_interval_time	
		IF @@FETCH_STATUS = -1 BREAK;
		
		set @sqlstatement3=@sqlstatement3 + N', cast(t'+ cast(@v_snap_id as varchar) +'.datos as nvarchar(16)) as ['+ cast(@v_end_interval_time as varchar)+']'
		set @sqlstatement2=@sqlstatement2 + N'
		join(
			select 
			ROW_NUMBER() over(order by snap_id desc) u
			, Datos
			from #t_tabla_orden
			where snap_id = '+ cast(@v_snap_id as varchar) +'
			) t'+ cast(@v_snap_id as varchar) +'
			on t1.u=t'+ cast(@v_snap_id as varchar) +'.u'
		
		
	END		
	CLOSE c_snapshot
	DEALLOCATE c_snapshot	
	
	select * into #t_tabla_orden from @t_tabla_orden
	set @sqlstatement2=@sqlstatement3+@sqlstatement2
	EXEC sp_executesql @sqlstatement2
	
	

end
GO
