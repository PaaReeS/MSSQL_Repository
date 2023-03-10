/****** Object:  StoredProcedure [dbo].[proc_awr_top]    Script Date: 07/27/2020 14:31:18 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO


create PROCEDURE [dbo].[proc_awr_top](@p_begin_snap int, @p_end_snap int, @p_metric_code varchar(3), @p_limit_down_exec int)  with encryption
--@res nvarchar(255) out
AS
BEGIN
	set nocount on

	DECLARE @t_tabletop_proc TABLE(
			procid int IDENTITY(1,1) NOT NULL,
			dbname varchar(50),
			procname varchar(50))

	DECLARE @t_tabletop TABLE(
			end_interval_time datetime,
			position integer,
			dbname varchar(50),
			procname varchar(50),
			cached_time datetime,
			execute_count integer,
			delta_value float,
			delta_value_exec float,
			percentage float
			)
			
	declare @v_snap_id integer
	
	declare @sqlstatement NVARCHAR(4000)
	declare @v_d_end_interval_time datetime
	declare @v_d_snap_id integer
	declare @v_d_dbname varchar(50)
	declare @v_d_procname varchar(50)
	declare @v_d_cached_time datetime
	declare @v_d_exec_count float
	declare @v_d_vdelta float
	declare @v_d_vdelta_rat float
	declare @v_d_percen float
	declare @v_d_position integer
	declare @v_d_procid integer
	declare @v_tabla_date varchar(50)
	declare @vmetric_base varchar(50)
	declare @vmetric_name varchar(50)
	declare @v_limit int
	declare @v_total_metric float
	declare @v_perc_total_explained nvarchar(5)
	DECLARE c_snaphost CURSOR FOR 
	select snap_id
	from dba_hist_snapshot
	where snap_id between @p_begin_snap and @p_end_snap
	order by snap_id

	DECLARE c_tabla CURSOR FOR 
	select  distinct CONVERT(VARCHAR(10), end_interval_time, 103)+ ' '  + CONVERT(VARCHAR(5), end_interval_time, 108) as date
	from @t_tabletop
	order by date
	
	set @v_limit = 10
	
	select @vmetric_base = metric_base, @vmetric_name = metric_name from dba_hist_control where metric_code = lower(@p_metric_code)
	
	if @p_metric_code = 'ec'
	begin
		set @vmetric_base = 'total_elapsed_time'
		set @vmetric_name = 'total_elapsed_time'
	   
		print('-------------------------------------------------------------------------------------------------------')
		print('| DELTA_VALUE: total_elapsed_time                                                                     |')
		print('| LIST_ORDER_BY: execute_count                                                                        |')
		print('-------------------------------------------------------------------------------------------------------')
		print('')
	end
	else
	begin
		print('-------------------------------------------------------------------------------------------------------')
		print('| DELTA_VALUE: '+upper(@vmetric_name)+'                                                                |')
		print('| LIST_ORDER_BY: '+upper(@vmetric_name)+'                                                              |')
		print('-------------------------------------------------------------------------------------------------------')
		print('')
	end
	
	open c_snaphost
	FETCH NEXT FROM c_snaphost INTO @v_snap_id
	
	WHILE @@FETCH_STATUS = 0  
	BEGIN

		if @p_metric_code = 'ec'
			set @sqlstatement = 'Declare c_snaphost_delta CURSOR GLOBAL FOR  select sum(snap2.execution_count - isnull(snap1.execution_count,0)) as total from '
		else
			set @sqlstatement = 'Declare c_snaphost_delta CURSOR GLOBAL FOR select sum(snap2.'+@vmetric_base+' - isnull(snap1.'+@vmetric_base+',0)) as total from '
		
		set @sqlstatement = @sqlstatement + '(select s.end_interval_time, s.snap_id, t.database_id as dbname, OBJECT_NAME(t.object_id, t.database_id) as procname,t.execution_count,t.cached_time,t.'+@vmetric_base+'
			from dba_hist_snapshot s, dba_hist_dm_exec_procedure_stats t
			where s.snap_id = t.snap_id and s.snap_id = '+ cast(@v_snap_id as varchar) +'
			and db_name(t.database_id) not in (''mdw'',''msdb'',''master'')) snap2
			left outer join
			(select s.snap_id, t.database_id as dbname, OBJECT_NAME(t.object_id, t.database_id) as procname,t.execution_count,t.cached_time,t.'+@vmetric_base+'
			from dba_hist_snapshot s, dba_hist_dm_exec_procedure_stats t
			where s.snap_id = t.snap_id and s.snap_id = '+ cast((@v_snap_id - 1) as varchar) +'
			and db_name(t.database_id) not in (''mdw'',''msdb'',''master'')) snap1
			on snap1.dbname = snap2.dbname and snap1.procname = snap2.procname and snap1.cached_time = snap2.cached_time
			where snap2.execution_count - isnull(snap1.execution_count,0) > 0'
		exec sp_executesql @sqlstatement
		open c_snaphost_delta
		FETCH NEXT FROM c_snaphost_delta INTO @v_total_metric
		CLOSE c_snaphost_delta
		DEALLOCATE c_snaphost_delta

			

		set @sqlstatement = 'Declare c_snaphost_delta CURSOR GLOBAL FOR 
			select snap2.snap_id,snap2.end_interval_time,snap2.dbname,snap2.procname,snap2.cached_time,snap2.execution_count - isnull(snap1.execution_count,0) as vexec,'
			
		if @p_metric_code in('ec','et','etr','wt','wtr')
			set @sqlstatement = @sqlstatement + '(snap2.'+@vmetric_base+' - isnull(snap1.'+@vmetric_base+',0))/1000000 as vdelta,
			cast(1.0*((snap2.'+@vmetric_base+' - isnull(snap1.'+@vmetric_base+',0))/1000000)/(snap2.execution_count - isnull(snap1.execution_count,0)) as decimal(20,4)) as vdelta_rat,'
		else
			set @sqlstatement = @sqlstatement + '(snap2.'+@vmetric_base+' - isnull(snap1.'+@vmetric_base+',0)) as vdelta,
			cast(1.0*((snap2.'+@vmetric_base+' - isnull(snap1.'+@vmetric_base+',0)))/(snap2.execution_count - isnull(snap1.execution_count,0)) as decimal(20,4)) as vdelta_rat,'
		
		if @p_metric_code in('ec')
			set @sqlstatement = @sqlstatement + '(snap2.execution_count - isnull(snap1.execution_count,0))*100/'+cast(@v_total_metric as varchar) +' as vpercen '
		else
			set @sqlstatement = @sqlstatement + '(snap2.'+@vmetric_base+' - isnull(snap1.'+@vmetric_base+',0))*100/'+cast(@v_total_metric as varchar) +' as vpercen '

		set @sqlstatement = @sqlstatement + 'from 
			(select s.end_interval_time, s.snap_id, t.database_id as dbname, OBJECT_NAME(t.object_id, t.database_id) as procname,t.execution_count,t.cached_time,t.'+@vmetric_base+'
			from dba_hist_snapshot s, dba_hist_dm_exec_procedure_stats t
			where s.snap_id = t.snap_id and s.snap_id = '+ cast(@v_snap_id as varchar) +'
			and db_name(t.database_id) not in (''mdw'',''msdb'',''master'')) snap2
			left outer join
			(select s.snap_id, t.database_id as dbname, OBJECT_NAME(t.object_id, t.database_id) as procname,t.execution_count,t.cached_time,t.'+@vmetric_base+'
			from dba_hist_snapshot s, dba_hist_dm_exec_procedure_stats t
			where s.snap_id = t.snap_id and s.snap_id = '+ cast((@v_snap_id - 1) as varchar) +'
			and db_name(t.database_id) not in (''mdw'',''msdb'',''master'')) snap1
			on snap1.dbname = snap2.dbname and snap1.procname = snap2.procname and snap1.cached_time = snap2.cached_time
			where snap2.execution_count - isnull(snap1.execution_count,0) > 0'
			
			if @p_limit_down_exec is not null
				set @sqlstatement = @sqlstatement + ' and snap2.execution_count - isnull(snap1.execution_count,0) > ' + cast(@p_limit_down_exec as varchar)
			
			
			if @p_metric_code = 'ec'
				set @sqlstatement = @sqlstatement + ' order by vexec desc'
			else
				if @vmetric_base = @vmetric_name
					set @sqlstatement = @sqlstatement + ' order by vdelta desc'
				else
					set @sqlstatement = @sqlstatement + ' order by vdelta_rat desc'
			
		exec sp_executesql @sqlstatement
		
		open c_snaphost_delta
		FETCH NEXT FROM c_snaphost_delta INTO @v_d_snap_id,@v_d_end_interval_time,@v_d_dbname,@v_d_procname,@v_d_cached_time,@v_d_exec_count,@v_d_vdelta,@v_d_vdelta_rat,@v_d_percen

		set @v_d_position = 1
		WHILE @@FETCH_STATUS = 0  
		BEGIN
			set @v_d_procid = null
			select @v_d_procid = procid from @t_tabletop_proc where dbname = @v_d_dbname and procname = @v_d_procname
			
			if @v_d_procid is null
			begin
				insert into @t_tabletop_proc values(@v_d_dbname,@v_d_procname)
				select @v_d_procid = procid from @t_tabletop_proc where dbname = @v_d_dbname and procname = @v_d_procname
			end
			
			--if @vmetric_base <> @vmetric_name
			--	set @v_d_vdelta = @v_d_vdelta_rat
			
			insert into @t_tabletop values(@v_d_end_interval_time,@v_d_position,@v_d_dbname,@v_d_procname,@v_d_cached_time,@v_d_exec_count,@v_d_vdelta,@v_d_vdelta_rat,@v_d_percen)
			set @v_d_position = @v_d_position + 1
		
			FETCH NEXT FROM c_snaphost_delta INTO @v_d_snap_id,@v_d_end_interval_time,@v_d_dbname,@v_d_procname,@v_d_cached_time,@v_d_exec_count,@v_d_vdelta,@v_d_vdelta_rat,@v_d_percen
		
			if @v_d_position > @v_limit
				break;
		END
		
		CLOSE c_snaphost_delta
		DEALLOCATE c_snaphost_delta

		FETCH NEXT FROM c_snaphost INTO @v_snap_id
	END
		
	CLOSE c_snaphost
	DEALLOCATE c_snaphost

	open c_tabla
	FETCH NEXT FROM c_tabla INTO @v_tabla_date
	--select @v_tabla_date
	WHILE @@FETCH_STATUS = 0  
	BEGIN
		set @v_perc_total_explained = (select CONVERT(varchar, CAST(sum(percentage) AS money), 1) from @t_tabletop	where CONVERT(VARCHAR(10), end_interval_time, 103)+ ' '  + CONVERT(VARCHAR(5), end_interval_time, 108) = @v_tabla_date);
		--set @v_perc_total_explained = (select CAST(format(sum(percentage),'###########0.0') as varchar(4)) from @t_tabletop	where cast(end_interval_time as varchar(14)) = @v_tabla_date);
		print('perc_total_explained: '+@v_perc_total_explained +'%');
		print('---------------------------');
		select 
		CAST(replace(convert(varchar(16),end_interval_time,120),'-','') as varchar(15)) as date,
		--cast(format(end_interval_time, 'ddMMyyyy HH\:mm') as varchar(14)) as date,
		cast(position as varchar(3)) as pos,CAST(dbname as varchar(5)) as dbname,CAST(procname as varchar(60)) as procname,
		cached_time,
		CAST(execute_count as varchar(10)) as execute_count,
		CONVERT(varchar, CAST(delta_value AS money), 2) as delta_value,
		--CAST(format(delta_value,'###########0.000') as varchar(10)) as delta_valueold,
		CONVERT(varchar, CAST(delta_value_exec AS money), 2) as delta_value_exec,
		--CAST(format(delta_value_exec,'###########0.000') as varchar(10)) as delta_value_execold,
		CONVERT(varchar, CAST(percentage AS money), 1) as perc
		--CAST(format(percentage,'###########0.0') as varchar(4)) as percold
		from @t_tabletop
		where CONVERT(VARCHAR(10), end_interval_time, 103)+ ' '  + CONVERT(VARCHAR(5), end_interval_time, 108) = @v_tabla_date
		order by position;
		print('');
		FETCH NEXT FROM c_tabla INTO @v_tabla_date	
	END
	
	CLOSE c_tabla
	DEALLOCATE c_tabla
	--select procid,dbname,procname from @t_tabletop_proc order by procid
	
END;

SET ANSI_NULLS ON
