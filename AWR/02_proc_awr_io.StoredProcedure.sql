/****** Object:  StoredProcedure [dbo].[proc_awr_io]    Script Date: 15/10/2019 15:23:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create procedure [dbo].[proc_awr_io](@p_begin_snap int, @p_end_snap int, @p_top_count int, @p_column nvarchar(30))  with encryption
as
begin
	set nocount on
	
	declare @t_tabla_orden table (
	snap_id integer
	, pos integer
	, pos2 integer
	, texto nvarchar(15)
	, datos nvarchar(60)
	) 
	
	declare @snap_id integer
	declare @q_end_interval_time datetime
	declare @q_file_type nvarchar(10)
	declare @q_db_name nvarchar(60)
	declare @q_column bigint
	declare	@pos integer
	declare @q_snap_id integer 


	declare @sqlstatement nvarchar(4000)
	declare @sqlstatement2 nvarchar(4000)
	declare @sqlstatement3 nvarchar(4000)
	declare @v_snap_id integer
	declare @v_end_interval_time nvarchar(20)
	
	if not exists (select cast(column_name as varchar(25)) as column_name from INFORMATION_SCHEMA.COLUMNS where table_name ='dba_hist_dm_io_virtual_file_stats' and table_catalog=(select db_name(DB_ID())) and column_name = @p_column)
	begin
		print('Esa columna no existe. ¿Seguro que estas consultando el procedimiento correcto?. Aqui las tienes, vuelve a probar suerte...')
		print(' ');
		select cast(column_name as varchar(25)) as column_name from INFORMATION_SCHEMA.COLUMNS where table_name ='dba_hist_dm_io_virtual_file_stats' and table_catalog=(select db_name(DB_ID()))
		return
	end
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
	FETCH NEXT FROM c_snapshot INTO @v_snap_id, @v_end_interval_time	
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
		set @sqlstatement =	'declare c_snap_query cursor for
			select top '+ cast(@p_top_count as varchar) +'
			snap2.snap_id
			, snap2.end_interval_time
			, case 
				when snap2.type = 0 then ''row'' 
				when snap2.type = 1 then ''log'' 
				when snap2.type = 2 then ''filestream'' 
				when snap2.type = 3 then ''###'' 
				when snap2.type = 4 then ''fulltext'' 
				else ''####'' 
			  end as file_type
			, db_name(snap2.database_id) as db_name
			, snap2.'+ @p_column +'-snap1.'+ @p_column +' as '+ @p_column +'
			from(
				select
				s.snap_id
				, s.end_interval_time
				, dm.type
				, dm.database_id
				, dm.sample_ms
				, dm.num_of_reads
				, dm.num_of_bytes_read
				, dm.io_stall_read_ms
				, dm.io_stall_queued_read_ms
				, dm.num_of_writes
				, dm.num_of_bytes_written
				, dm.io_stall_write_ms
				, dm.io_stall_queued_write_ms
				, dm.io_stall
				, dm.size_on_disk_bytes
				from dba_hist_dm_io_virtual_file_stats dm
					join dba_hist_snapshot s
						on dm.snap_id=s.snap_id
				where s.snap_id =  '+ cast(@v_snap_id as varchar) +'				
				) snap2
				left outer join
				(
				select 
				s.snap_id
				, s.end_interval_time
				, dm.type
				, dm.database_id
				, dm.sample_ms
				, dm.num_of_reads
				, dm.num_of_bytes_read
				, dm.io_stall_read_ms
				, dm.io_stall_queued_read_ms
				, dm.num_of_writes
				, dm.num_of_bytes_written
				, dm.io_stall_write_ms
				, dm.io_stall_queued_write_ms
				, dm.io_stall
				, dm.size_on_disk_bytes
				from dba_hist_dm_io_virtual_file_stats dm
					join dba_hist_snapshot s
						on dm.snap_id=s.snap_id
				where s.snap_id ='+ cast((@v_snap_id -1)as varchar) +'
				) snap1
					on (snap1.type = snap2.type and snap1.database_id=snap2.database_id)
				order by '+ cast(@p_column as varchar) +' desc'										
		exec sp_executesql @sqlstatement
		open c_snap_query
		fetch next from c_snap_query into @q_snap_id, @q_end_interval_time, @q_file_type, @q_db_name, @q_column
		
		set @pos = 1
		while @@fetch_status = 0  
		begin
			insert into @t_tabla_orden (snap_id, pos, pos2, texto, datos) values (@q_snap_id, @pos, 1,'database', @q_db_name);
			insert into @t_tabla_orden (snap_id, pos, pos2, texto, datos) values (@q_snap_id, @pos, 2, 'type', @q_file_type);
			insert into @t_tabla_orden (snap_id, pos, pos2, texto, datos) values (@q_snap_id, @pos, 3, 'value', @q_column);
			insert into @t_tabla_orden (snap_id, pos, pos2, texto, datos) values (@q_snap_id, @pos, 0, ' ', ' ');
			
			set @pos = @pos + 1
		
			fetch next from c_snap_query into @q_snap_id, @q_end_interval_time, @q_file_type, @q_db_name, @q_column
		end
					
		close c_snap_query
		DEALLOCATE c_snap_query
		
		fetch next from c_snapshot into @v_snap_id, @v_end_interval_time	
		if @@fetch_status = -1 break;
		
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
		
		
	end		
	close c_snapshot
	DEALLOCATE c_snapshot	
	
	select * into #t_tabla_orden from @t_tabla_orden
	set @sqlstatement2=@sqlstatement3+@sqlstatement2
	exec sp_executesql @sqlstatement2
	
end
GO
