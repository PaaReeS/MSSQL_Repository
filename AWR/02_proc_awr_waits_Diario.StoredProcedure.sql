/****** Object:  StoredProcedure [dbo].[proc_awr_waits]    Script Date: 15/10/2019 15:23:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[proc_awr_waits_D_S](@p_begin_snap int, @p_end_snap int, @p_top_count int, @p_order_by nvarchar(40), @p_wait_class nvarchar(40) = null)  with encryption
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @t_tabla_orden TABLE (
	snap_id integer
	, pos integer
	, pos2 integer
	, texto nvarchar(10)
	, datos nvarchar(60)
	) 
	
	DECLARE @v_snap_id_max integer
	DECLARE @v_snap_id_min integer
	DECLARE @v_end_interval_time nvarchar(20)
	DECLARE @sqlstatement NVARCHAR(4000)
	DECLARE @sqlstatement2 NVARCHAR(4000)
	DECLARE @sqlstatement3 NVARCHAR(4000)
	DECLARE @q_wait_type nvarchar(60)
	DECLARE @q_wait_class nvarchar(60)
	DECLARE @v_order_by nvarchar(60)
	DECLARE @q_snap_id integer
	DECLARE	@q_end_interval_time datetime
	DECLARE @q_waiting_tasks_count bigint
	DECLARE @q_wait_time_ms float
	DECLARE @q_max_wait_time_ms bigint
	DECLARE @q_wait_time_per_task bigint
	DECLARE	@pos integer

	set @v_order_by=(select metric_base from dba_hist_control where metric_code=@p_order_by and procname='proc_awr_waits')
	if  NULLIF(@v_order_by, '') IS NULL
	BEGIN
		print('¿Tendras que ordenar por algo que exista no? Tipo de ORDER BY no valido. Saliendo...')
		Return
	END
	if not exists (select snap_id from dba_hist_snapshot where snap_id in (@p_begin_snap, @p_end_snap))
	BEGIN
		print('Snapshots no existentes. Saliendo...')
		Return
	END	
	
	set @p_wait_class = coalesce(@p_wait_class,'%')
	DECLARE c_snapshot CURSOR FOR
	select max(snap_id),min(snap_id),CONVERT(VARCHAR(10), end_interval_time, 103)
	from dba_hist_snapshot
	where snap_id between @p_begin_snap and @p_end_snap
	group by CONVERT(VARCHAR(10), end_interval_time, 103)
	order by CONVERT(VARCHAR(10), end_interval_time, 103) desc
	
	OPEN c_snapshot
	FETCH NEXT FROM c_snapshot INTO @v_snap_id_max,@v_snap_id_min, @v_end_interval_time	
	set @sqlstatement3=N'select t1.texto as [ ], cast(t1.datos as nvarchar(16))  as ['+ cast(@v_end_interval_time as varchar)+']'
	set @sqlstatement2=N'
		from(
			select 
			ROW_NUMBER() over(order by snap_id desc) u
			, texto
			, Datos
			from #t_tabla_orden
			where snap_id = '+ cast(@v_snap_id_max as varchar) +'
		) t1
		' 
		
	WHILE 1=1  
	BEGIN		
		set @sqlstatement =	'DECLARE c_snap_query CURSOR FOR
			select top '+ cast(@p_top_count as varchar) +'
			snap2.snap_id
			, snap2.end_interval_time
			, snap2.wait_type 
			, snap2.wait_class
			, (snap2.waiting_tasks_count-snap1.waiting_tasks_count) waiting_tasks_count
			, cast((snap2.wait_time_ms-snap1.wait_time_ms)/1000.00 as decimal(10,2)) wait_time_ms
			, cast((snap2.max_wait_time_ms-snap1.max_wait_time_ms) as decimal(10,2)) max_wait_time_ms
			, CAST((isnull((snap2.wait_time_ms-isnull(snap1.wait_time_ms,0))/nullif((snap2.waiting_tasks_count-snap1.waiting_tasks_count),0),0)) as decimal(10,2))   wait_time_per_task
			from(
				select 
				s.snap_id
				, s.end_interval_time
				, dm.wait_type
				, c.wait_class
				, dm.waiting_tasks_count
				, dm.wait_time_ms
				, dm.max_wait_time_ms
				from dba_hist_dm_os_wait_stats dm
					join dba_hist_snapshot s
						on dm.snap_id=s.snap_id
					left outer join dba_hist_wait_class c
						on dm.wait_type=c.wait_type
				where c.wait_class <> ''IGNORE''
				and s.snap_id =  '+ cast(@v_snap_id_max as varchar) +'
				and c.wait_class like ''%'+ cast(@p_wait_class as varchar) +'%'' 
				) snap2
				left outer join
				(
				select 
				s.snap_id
				, s.end_interval_time
				, dm.wait_type
				, c.wait_class
				, dm.waiting_tasks_count
				, dm.wait_time_ms
				, dm.max_wait_time_ms
				from dba_hist_dm_os_wait_stats dm
					join dba_hist_snapshot s
						on dm.snap_id=s.snap_id
					left outer join dba_hist_wait_class c
						on dm.wait_type=c.wait_type
				where c.wait_class <> ''IGNORE''
				and s.snap_id ='+ cast((@v_snap_id_min)as varchar) +'
				and c.wait_class like ''%'+ cast(@p_wait_class as varchar) +'%'' 
				) snap1
					on snap1.wait_type = snap2.wait_type
				order by '+ @v_order_by +' desc'
		EXEC sp_executesql @sqlstatement
		open c_snap_query
		Fetch next from c_snap_query into @q_snap_id, @q_end_interval_time, @q_wait_type, @q_wait_class, @q_waiting_tasks_count
		, @q_wait_time_ms, @q_max_wait_time_ms, @q_wait_time_per_task
		
		set @pos = 1
		WHILE @@FETCH_STATUS = 0  
		BEGIN
			insert into @t_tabla_orden (snap_id, pos, pos2, texto, Datos) values (@q_snap_id, @pos, 1,'WAIT EVENT', @q_wait_type);
			insert into @t_tabla_orden (snap_id, pos, pos2, texto, Datos) values (@q_snap_id, @pos, 2,'WAIT CLASS', @q_wait_class);
			insert into @t_tabla_orden (snap_id, pos, pos2, texto, Datos) values (@q_snap_id, @pos, 3, 'TIME (s)', @q_wait_time_ms);
			insert into @t_tabla_orden (snap_id, pos, pos2, texto, Datos) values (@q_snap_id, @pos, 4, 'COUNT', @q_waiting_tasks_count);
			insert into @t_tabla_orden (snap_id, pos, pos2, texto, Datos) values (@q_snap_id, @pos, 0, ' ', ' ');
			
			set @pos = @pos + 1
		
			Fetch next from c_snap_query into @q_snap_id, @q_end_interval_time, @q_wait_type, @q_wait_class, @q_waiting_tasks_count
			, @q_wait_time_ms, @q_max_wait_time_ms, @q_wait_time_per_task
		END
					
		CLOSE c_snap_query
		DEALLOCATE c_snap_query
		
		FETCH NEXT FROM c_snapshot INTO @v_snap_id_max,@v_snap_id_min ,@v_end_interval_time	
		IF @@FETCH_STATUS = -1 BREAK;
		
		set @sqlstatement3=@sqlstatement3 + N', cast(t'+ cast(@v_snap_id_max as varchar) +'.datos as nvarchar(16)) as ['+ cast(@v_end_interval_time as varchar)+']'
		set @sqlstatement2=@sqlstatement2 + N'
		join(
			select 
			ROW_NUMBER() over(order by snap_id desc) u
			, Datos
			from #t_tabla_orden
			where snap_id = '+ cast(@v_snap_id_max as varchar) +'
			) t'+ cast(@v_snap_id_max as varchar) +'
			on t1.u=t'+ cast(@v_snap_id_max as varchar) +'.u'
		
		
	END		
	CLOSE c_snapshot
	DEALLOCATE c_snapshot	
	
	select * into #t_tabla_orden from @t_tabla_orden
	set @sqlstatement2=@sqlstatement3+@sqlstatement2
	EXEC sp_executesql @sqlstatement2
END
GO
