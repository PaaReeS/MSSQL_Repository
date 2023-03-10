/****** Object:  StoredProcedure [dbo].[proc_awr_io_list]    Script Date: 15/10/2019 15:23:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create procedure [dbo].[proc_awr_io_list](@p_host nvarchar(50),@p_begin_snap int, @p_end_snap int, @p_db_name nvarchar(60))  with encryption
as
begin
	set nocount on
	
	declare @t_tabla table (
	snap_id integer
	, db_name nvarchar(60)
	, file_type nvarchar(10)
	, end_interval_time	datetime
	, num_of_reads bigint
	, num_of_bytes_read bigint
	, io_stall_read_ms bigint
	, io_stall_queued_read_ms bigint
	, num_of_writes bigint
	, num_of_bytes_written bigint
	, io_stall_write_ms bigint
	, io_stall_queued_write_ms bigint
	, io_stall bigint
	, size_on_disk_bytes bigint
	) 
	
    declare @q_snap_id integer
	declare @q_file_type nvarchar(10)
	declare @q_db_name nvarchar(30)
	declare @q_end_interval_time datetime
	declare @q_num_of_reads bigint
	declare @q_num_of_bytes_read bigint
	declare @q_io_stall_read_ms bigint
	declare @q_io_stall_queued_read_ms bigint
	declare @q_num_of_writes bigint
	declare @q_num_of_bytes_written bigint
	declare @q_io_stall_write_ms bigint
	declare @q_io_stall_queued_write_ms bigint
	declare @q_io_stall bigint
	declare @q_size_on_disk_bytes bigint
	

	declare @sqlstatement nvarchar(4000)
	declare @sqlstatement2 nvarchar(4000)
	declare @sqlstatement3 nvarchar(4000)
	declare @v_snap_id integer
	declare @v_end_interval_time nvarchar(20)
	/*COMPROBACIONES PREVIAS A EXEC*/
	set @sqlstatement='if not exists (select snap_id from ' + @p_host + '..dba_hist_snapshot where snap_id in ('+cast(@p_begin_snap as nvarchar) +', '+cast(@p_end_snap as nvarchar)+'))
	begin
		print(''Snapshots no existentes. Ten más ojo. Saliendo...'')
		return
	end'	
	exec sp_executesql @sqlstatement
	if(@p_end_snap - @p_begin_snap > 15)
	begin
		print('Te has pasado tronco. Demasiada información pides. Saliendo...')
		return
	end
	set @sqlstatement='if not exists (select database_id from ' + @p_host + '..dba_hist_databases where name ='''+ @p_db_name +''')
	begin
		print(''Esa base de datos no existe tio. ¿Ya sabes que y donde buscar? Saliendo...'');
		select name from ' + @p_host + '..dba_hist_databases order by database_id asc
		return
	end'
	exec sp_executesql @sqlstatement
	/*DECLARACION DEL CURSOR*/
	set @sqlstatement='declare c_snapshot cursor for
	select snap_id, CONVERT(VARCHAR(10), end_interval_time, 103)+ '' '' + CONVERT(VARCHAR(5), end_interval_time, 108)
	from ' + @p_host + '..dba_hist_snapshot
	where snap_id between '+cast(@p_begin_snap as nvarchar) +' and '+cast(@p_end_snap as nvarchar)+'
	order by snap_id'
	exec sp_executesql @sqlstatement
	open c_snapshot
	fetch next from c_snapshot into @v_snap_id, @v_end_interval_time	

	while 1=1  
	begin			
		set @sqlstatement =	'declare c_snap_query cursor for
			select
			snap2.snap_id
			, (select name from ' + @p_host + '..dba_hist_databases where database_id=snap2.database_id) as db_name
			, case 
				when snap2.type = 0 then ''ROW'' 
				when snap2.type = 1 then ''LOG'' 
				when snap2.type = 2 then ''FILESTREAM'' 
				when snap2.type = 3 then ''###'' 
				when snap2.type = 4 then ''FULLTEXT'' 
				else ''####'' 
			  end as file_type
			, snap2.end_interval_time
			, snap2.num_of_reads-snap1.num_of_reads as num_of_reads
			, snap2.num_of_bytes_read-snap1.num_of_bytes_read as num_of_bytes_read
			, snap2.io_stall_read_ms-snap1.io_stall_read_ms as io_stall_read_ms
			, snap2.io_stall_queued_read_ms-snap1.io_stall_queued_read_ms as io_stall_queued_read_ms
			, snap2.num_of_writes-snap1.num_of_writes as num_of_writes
			, snap2.num_of_bytes_written-snap1.num_of_bytes_written as num_of_bytes_written
			, snap2.io_stall_write_ms-snap1.io_stall_write_ms as io_stall_write_ms
			, snap2.io_stall_queued_write_ms-snap1.io_stall_queued_write_ms as io_stall_queued_write_ms
			, snap2.io_stall-snap1.io_stall as io_stall
			, snap2.size_on_disk_bytes-snap1.size_on_disk_bytes as size_on_disk_bytes
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
				from ' + @p_host + '..dba_hist_dm_io_virtual_file_stats dm
					join ' + @p_host + '..dba_hist_snapshot s
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
				from ' + @p_host + '..dba_hist_dm_io_virtual_file_stats dm
					join ' + @p_host + '..dba_hist_snapshot s
						on dm.snap_id=s.snap_id
				where s.snap_id ='+ cast((@v_snap_id -1)as varchar) +'
				) snap1
					on (snap1.type = snap2.type and snap1.database_id=snap2.database_id)
				where snap2.database_id =(select database_id from ' + @p_host + '..dba_hist_databases where name='''+ cast(@p_db_name as varchar)+''')
				order by  file_type desc'										
		exec sp_executesql @sqlstatement
		OPEN c_snap_query
		FETCH NEXT FROM c_snap_query into @q_snap_id, @q_db_name, @q_file_type, @q_end_interval_time, @q_num_of_reads, @q_num_of_bytes_read, @q_io_stall_read_ms
		, @q_io_stall_queued_read_ms, @q_num_of_writes, @q_num_of_bytes_written, @q_io_stall_write_ms, @q_io_stall_queued_write_ms, @q_io_stall, @q_size_on_disk_bytes
		
		while @@fetch_status = 0  
		begin
			insert into @t_tabla (snap_id, db_name, file_type, end_interval_time, num_of_reads, num_of_bytes_read, io_stall_read_ms,
			io_stall_queued_read_ms, num_of_writes, num_of_bytes_written, io_stall_write_ms, io_stall_queued_write_ms, io_stall, size_on_disk_bytes) 
			values (@q_snap_id, @q_db_name, @q_file_type, @q_end_interval_time, @q_num_of_reads, @q_num_of_bytes_read, @q_io_stall_read_ms
			, @q_io_stall_queued_read_ms, @q_num_of_writes, @q_num_of_bytes_written, @q_io_stall_write_ms, @q_io_stall_queued_write_ms, @q_io_stall, @q_size_on_disk_bytes);
		
			fetch next from c_snap_query into @q_snap_id, @q_db_name, @q_file_type, @q_end_interval_time, @q_num_of_reads, @q_num_of_bytes_read, @q_io_stall_read_ms
			, @q_io_stall_queued_read_ms, @q_num_of_writes, @q_num_of_bytes_written, @q_io_stall_write_ms, @q_io_stall_queued_write_ms, @q_io_stall, @q_size_on_disk_bytes
		end
					
		CLOSE c_snap_query
		DEALLOCATE c_snap_query
		
		fetch next from c_snapshot into @v_snap_id, @v_end_interval_time	
		if @@fetch_status = -1 break;
		
	end		
	CLOSE c_snapshot
	DEALLOCATE c_snapshot	
	select  
	  cast(db_name as nvarchar (25)) as db_name
	, cast(file_type  as nvarchar(5)) as ft
	, CONVERT(VARCHAR(10), end_interval_time, 103)+ ' ' + CONVERT(VARCHAR(5), end_interval_time, 108) as snap
	, CAST(isnull(io_stall_read_ms / ( 1.0 *  nullif(num_of_reads,0) ),0) AS INT) as AVG_Read_Stall
	, CAST(isnull(io_stall_write_ms / ( 1.0 * nullif(num_of_writes,0) ),0) AS INT) as AVG_Write_Stall
	, cast(num_of_reads             as nvarchar(15)) as num_of_reads 
	, cast(cast(num_of_bytes_read/1024.00/1024.00 as numeric(30,2)) as nvarchar(20)) as num_of_Mb_read 
	, cast(io_stall_read_ms         as nvarchar(15)) as io_stall_read_ms 
	, cast(io_stall_queued_read_ms  as nvarchar(15)) as io_stall_queued_read_ms 
	, cast(num_of_writes            as nvarchar(15)) as num_of_writes 
	, cast(cast(num_of_bytes_written/1024.00/1024.00  as numeric(30,2)) as nvarchar(15)) as num_of_Mb_written 
	, cast(io_stall_write_ms        as nvarchar(15)) as io_stall_write_ms 
	, cast(io_stall_queued_write_ms as nvarchar(15)) as io_stall_queued_write_ms 
	, cast(io_stall                 as nvarchar(15)) as io_stall 
	, cast(cast(size_on_disk_bytes/1024.00/1024.00  as numeric(30,2)) as nvarchar(15)) as size_on_disk_Mb	
	from @t_tabla where file_type = 'ROW' 
	union
	select  
	  cast(db_name as nvarchar (25)) as db_name
	, cast(file_type  as nvarchar(5)) as ft
	, CONVERT(VARCHAR(10), end_interval_time, 103)+ ' ' + CONVERT(VARCHAR(5), end_interval_time, 108) as snap
	, CAST(isnull(io_stall_read_ms / ( 1.0 *  nullif(num_of_reads,0) ),0) AS INT) as AVG_Read_Stall
	, CAST(isnull(io_stall_write_ms / ( 1.0 * nullif(num_of_writes,0) ),0) AS INT) as AVG_Write_Stall
	, cast(num_of_reads             as nvarchar(15)) as num_of_reads 
	, cast(cast(num_of_bytes_read/1024.00/1024.00 as numeric(30,2)) as nvarchar(20)) as num_of_Mb_read 
	, cast(io_stall_read_ms         as nvarchar(15)) as io_stall_read_ms 
	, cast(io_stall_queued_read_ms  as nvarchar(15)) as io_stall_queued_read_ms 
	, cast(num_of_writes            as nvarchar(15)) as num_of_writes 
	, cast(cast(num_of_bytes_written/1024.00/1024.00  as numeric(30,2)) as nvarchar(15)) as num_of_Mb_written 
	, cast(io_stall_write_ms        as nvarchar(15)) as io_stall_write_ms 
	, cast(io_stall_queued_write_ms as nvarchar(15)) as io_stall_queued_write_ms 
	, cast(io_stall                 as nvarchar(15)) as io_stall 
	, cast(cast(size_on_disk_bytes/1024.00/1024.00  as numeric(30,2)) as nvarchar(15)) as size_on_disk_Mb	
	from @t_tabla where file_type <> 'ROW' order by ft desc,snap asc
end
GO
