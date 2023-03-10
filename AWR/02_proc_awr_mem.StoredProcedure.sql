/****** Object:  StoredProcedure [dbo].[proc_awr_mem]    Script Date: 15/10/2019 15:23:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE procedure [dbo].[proc_awr_mem](@p_begin_snap int, @p_end_snap int)  with encryption
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
	declare @q_Percentage_free nvarchar(10)
	declare @q_AUM_USED nvarchar(10)
	declare @q_USED nvarchar(10)
	declare @q_FREE nvarchar(10)
	declare @q_TOTAL nvarchar(10)
	declare @q_system_memory_state_desc nvarchar(4)
	DECLARE	@pos integer
--Revisar
	declare @sqlstatement nvarchar(4000)
	declare @sqlstatement2 nvarchar(4000)
	declare @sqlstatement3 nvarchar(4000)
	--
	declare @v_snap_id integer
	declare @v_end_interval_time nvarchar(20)
	
	if not exists (select snap_id from dba_hist_snapshot where snap_id in (@p_begin_snap, @p_end_snap))
	begin
		print('Snapshots no existentes. Ten más ojo. Saliendo...')
		return
	end	
	if(@p_end_snap - @p_begin_snap > 15)
	begin
		print('Te has pasado tronco. Demasiada información pides. Saliendo...')
		return
	end
	
	
	declare c_snapshot cursor for
	select snap_id,CONVERT(VARCHAR(10), end_interval_time, 103)+ ' ' + CONVERT(VARCHAR(5), end_interval_time, 108)
	from dba_hist_snapshot
	where snap_id between @p_begin_snap and @p_end_snap
	order by snap_id
	
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
			/*
			, snap2.total_physical_memory_kb/1024.0/1024.0 as total_physical_memory_Gb
			, snap2.available_physical_memory_kb-snap1.available_physical_memory_kb as available_physical_memory_kb
			, snap2.total_page_file_kb/1024.0/1024.0 as total_page_file_Gb
			, snap2.available_page_file_kb-snap1.available_page_file_kb as available_page_file_kb
			, snap2.system_cache_kb-snap1.system_cache_kb as system_cache_kb
			, snap2.kernel_paged_pool_kb-snap1.kernel_paged_pool_kb as kernel_paged_pool_kb
			, snap2.kernel_nonpaged_pool_kb-snap1.kernel_nonpaged_pool_kb as kernel_nonpaged_pool_kb
			*/	
		set @sqlstatement =	'DECLARE c_snap_query CURSOR FOR
			select
			snap2.snap_id
			, snap2.end_interval_time
			, cast(snap2.Percentage_free as decimal(10,2)) as Percentage_free
			, (snap2.used-snap1.used)/1024 as AUM_USED
			, snap2.used/1024 as USED
			, snap2.available_physical_memory_kb/1024 as FREE
			, snap2.total_physical_memory_kb/1024 as TOTAL
			, case when snap2.system_memory_state_desc like ''%high%'' then ''HIGH'' else ''LOW'' end as system_memory_state_desc
			from(
				select 
				s.snap_id
				, s.end_interval_time
				, 100 - (100 * CAST(dm.available_physical_memory_kb AS DECIMAL(18,3))/CAST(dm.total_physical_memory_kb AS DECIMAL(18,3)))  as Percentage_free
				, dm.total_physical_memory_kb
				, dm.total_physical_memory_kb - dm.available_physical_memory_kb as used
				, dm.available_physical_memory_kb
				, dm.system_memory_state_desc
				from dba_hist_dm_os_sys_memory dm
					join dba_hist_snapshot s
						on dm.snap_id=s.snap_id
				where s.snap_id =  '+ cast(@v_snap_id as varchar) +'
				) snap2
				left outer join
				(
				select 
				s.snap_id
				, s.end_interval_time
				, 100 - (100 * CAST(dm.available_physical_memory_kb AS DECIMAL(18,3))/CAST(dm.total_physical_memory_kb AS DECIMAL(18,3)))  as Percentage_free
				, dm.total_physical_memory_kb
				, dm.total_physical_memory_kb - dm.available_physical_memory_kb as used
				, dm.available_physical_memory_kb
				, dm.system_memory_state_desc
				from dba_hist_dm_os_sys_memory dm
					join dba_hist_snapshot s
						on dm.snap_id=s.snap_id
				where s.snap_id ='+ cast((@v_snap_id -1)as varchar) +'
				) snap1
					on snap1.snap_id = snap2.snap_id-1
				'										
		exec sp_executesql @sqlstatement
		open c_snap_query
		Fetch next from c_snap_query into @q_snap_id, @q_end_interval_time, @q_Percentage_free, @q_AUM_USED, @q_USED, @q_FREE, @q_TOTAL, @q_system_memory_state_desc
		
		set @pos = 1
		WHILE @@FETCH_STATUS = 0  
		BEGIN
			insert into @t_tabla_orden (snap_id, pos, pos2, texto, Datos) values (@q_snap_id, @pos, 1,'PERCENTAGE', @q_Percentage_free);
			insert into @t_tabla_orden (snap_id, pos, pos2, texto, Datos) values (@q_snap_id, @pos, 2, '/\USED (M)', @q_AUM_USED);
			insert into @t_tabla_orden (snap_id, pos, pos2, texto, Datos) values (@q_snap_id, @pos, 3, 'USED (M)', @q_USED);
			insert into @t_tabla_orden (snap_id, pos, pos2, texto, Datos) values (@q_snap_id, @pos, 3, 'FREE (M)', @q_FREE);
			insert into @t_tabla_orden (snap_id, pos, pos2, texto, Datos) values (@q_snap_id, @pos, 3, 'TOTAL (M)', @q_TOTAL);
			--insert into @t_tabla_orden (snap_id, pos, pos2, texto, Datos) values (@q_snap_id, @pos, 0, ' ', ' ');
			
			set @pos = @pos + 1
		
			Fetch next from c_snap_query into @q_snap_id, @q_end_interval_time, @q_Percentage_free, @q_AUM_USED, @q_USED, @q_FREE, @q_TOTAL, @q_system_memory_state_desc
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
	
	
	/*
	select  
	  --snap_id 
	  cast(db_name as nvarchar (25)) as db_name
	, cast(file_type  as nvarchar(5)) as ft
	, cast(format(end_interval_time,'dd/MM/yyyy hh:mm') as nvarchar(16)) as snap	
	, cast(num_of_reads             as nvarchar(10)) as num_of_reads 
	, cast(num_of_bytes_read        as nvarchar(15)) as num_of_bytes_read 
	, cast(io_stall_read_ms         as nvarchar(10)) as io_stall_read_ms 
	, cast(io_stall_queued_read_ms  as nvarchar(10)) as io_stall_queued_read_ms 
	, cast(num_of_writes            as nvarchar(10)) as num_of_writes 
	, cast(num_of_bytes_written     as nvarchar(15)) as num_of_bytes_written 
	, cast(io_stall_write_ms        as nvarchar(10)) as io_stall_write_ms 
	, cast(io_stall_queued_write_ms as nvarchar(10)) as io_stall_queued_write_ms 
	, cast(io_stall                 as nvarchar(8)) as io_stall 
	, cast(size_on_disk_bytes	    as nvarchar(10)) as size_on_disk_bytes	
	from @t_tabla where file_type = 'ROW' --order by db_name,file_type desc
	union
	select  
	  --snap_id 
	  cast(db_name as nvarchar (25)) as db_name
	, cast(file_type  as nvarchar(5)) as ft
	, cast(format(end_interval_time,'dd/MM/yyyy hh:mm') as nvarchar(16)) as snap	
	, cast(num_of_reads             as nvarchar(10)) as num_of_reads 
	, cast(num_of_bytes_read        as nvarchar(15)) as num_of_bytes_read 
	, cast(io_stall_read_ms         as nvarchar(10)) as io_stall_read_ms 
	, cast(io_stall_queued_read_ms  as nvarchar(10)) as io_stall_queued_read_ms 
	, cast(num_of_writes            as nvarchar(10)) as num_of_writes 
	, cast(num_of_bytes_written     as nvarchar(15)) as num_of_bytes_written 
	, cast(io_stall_write_ms        as nvarchar(10)) as io_stall_write_ms 
	, cast(io_stall_queued_write_ms as nvarchar(10)) as io_stall_queued_write_ms 
	, cast(io_stall                 as nvarchar(8)) as io_stall 
	, cast(size_on_disk_bytes	    as nvarchar(10)) as size_on_disk_bytes	
	from @t_tabla where file_type <> 'ROW' order by ft desc,snap asc*/
end
GO
