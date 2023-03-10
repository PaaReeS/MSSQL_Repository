/****** Object:  StoredProcedure [dbo].[proc_awr_list]    Script Date: 15/10/2019 15:23:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO


CREATE PROCEDURE [dbo].[proc_awr_list] (@p_host nvarchar(50)=null,@p_list varchar(3) = null,@p_end_interval_time nvarchar(10) = null)  with encryption
AS
BEGIN
	set nocount on
	declare @sqlstatement nvarchar(4000)
	
	if(@p_list is null)  
	begin
		print('')
		print('proc_awr_list p_host,p_list, p_end_interval_time (yyyymmdd) ')
		print('')
		print('DB: List_DB')
		print('SQ: proc_awr_top')
		print('SP: proc_awr_sp')
		print('W: proc_awr_waits')
		print('WG: proc_awr_waits_g')
		print('WDS: proc_awr_waits_D_S')
		print('IO: proc_awr_io')
		print('IOL: proc_awr_io_list')
		print('M: proc_awr_mem ')
		print('C: proc_awr_cpu')
		print('CH: proc_awr_cpu_hour')

		return
	end

	set @sqlstatement='select * from ' + @p_host + '..dba_hist_snapshot where cast(end_interval_time as date)= cast( cast('+@p_end_interval_time +'as nvarchar) as date) order by snap_id;'
	exec sp_executesql @sqlstatement
	print('');
	if upper(@p_list) = 'DB'
	begin		
	set @sqlstatement='select database_id,name from ' + @p_host + '..dba_hist_databases order by database_id;'
	exec sp_executesql @sqlstatement		 
	end
	if upper(@p_list) = 'SP'
	begin		
		print('proc_awr_sp        p_host,p_begin_snap, p_end_snap, p_name_sp')
		print('p_name_sp: Procedure name')
	end
	if upper(@p_list) = 'SQ'
	begin
		set @sqlstatement='select cast(metric_code as varchar(4)) as p_metric_code,cast(metric_name as varchar(40)) as metric_name from ' + @p_host + '..dba_hist_control where procname = ''proc_awr_top_sp'' order by metric_code;'
		exec sp_executesql @sqlstatement
		print('')
		print('proc_awr_top       p_host,p_begin_snap, p_end_snap, p_metric_code, p_limit_down_exec')
	end
	if upper(@p_list) = 'W'
	begin
		set @sqlstatement='select cast(metric_code as varchar(4)) as p_order_by,cast(metric_base as varchar(40)) as metric_name  from ' + @p_host + '..dba_hist_control where procname = ''proc_awr_waits'' order by metric_code;'
		exec sp_executesql @sqlstatement
		print('');
		set @sqlstatement='select distinct wait_class as p_wait_class  from ' + @p_host + '.dbo.dba_hist_wait_class'
		exec sp_executesql @sqlstatement
		print('null');
		print('');
		print('proc_awr_waits     p_host,p_begin_snap, p_end_snap, p_top, p_order_by, p_wait_class ')
	end
	if upper(@p_list) = 'WG'
	begin
		set @sqlstatement='select cast(metric_code as varchar(4)) as p_order_by,cast(metric_base as varchar(40)) as metric_name from ' + @p_host + '..dba_hist_control where procname= ''proc_awr_waits'' order by metric_name;'
		exec sp_executesql @sqlstatement
		print('');
		set @sqlstatement='select distinct wait_class as p_wait_class from ' + @p_host + '.dbo.dba_hist_wait_class'
		exec sp_executesql @sqlstatement
		print('null');
		print('');
		print('proc_awr_waits_g   p_host,p_begin_snap, p_end_snap, p_top, p_order_by, p_wait_class ')
	end
	if upper(@p_list) = 'WDS'
	begin
		set @sqlstatement='select cast(metric_code as varchar(4)) as p_order_by,cast(metric_base as varchar(40)) as metric_name from ' + @p_host + '..dba_hist_control where procname= ''proc_awr_waits'' order by metric_name;'
		exec sp_executesql @sqlstatement
		print('');
		set @sqlstatement='select distinct wait_class as p_wait_class from ' + @p_host + '.dbo.dba_hist_wait_class'
		exec sp_executesql @sqlstatement
		print('null');
		print('');
		print('proc_awr_waits_g   p_host,p_begin_snap, p_end_snap, p_top, p_order_by, p_wait_class ')
	end
	if upper(@p_list) = 'IO'
	begin
		set @sqlstatement='select cast(column_name as varchar(25)) as p_column from ' + @p_host + '.INFORMATION_SCHEMA.COLUMNS where table_name =''dba_hist_dm_io_virtual_file_stats'' and table_catalog=''' + @p_host + ''' and ordinal_position > 4;'
		exec sp_executesql @sqlstatement
		print('');
		print('proc_awr_io        p_host,p_begin_snap, p_end_snap, p_top, p_column')
	end
	if upper(@p_list) = 'IOL'
	begin
		set @sqlstatement='select database_id,name from ' + @p_host + '..dba_hist_databases order by database_id;'
		exec sp_executesql @sqlstatement	
		print('');
		print('proc_awr_io_list   p_host,p_begin_snap, p_end_snap, p_db_name')
	end
	if upper(@p_list) = 'M'
	begin	
		set @sqlstatement='select total_physical_memory_kb/1024 as [Total Memory] from ' + @p_host + '.sys.dm_os_sys_memory'
		exec sp_executesql @sqlstatement
		print('')                 
		print('proc_awr_mem       p_host,p_begin_snap, p_end_snap')
	end
	if upper(@p_list) = 'C'
	begin	
		print('')                 
		print('proc_awr_cpu       p_host,p_begin_snap, p_end_snap')
	end
	if upper(@p_list) = 'CH'
	begin	
		print('')                 
		print('proc_awr_cpu_hour       p_host,p_begin_snap')
	end
	
	
	
	
END
GO
