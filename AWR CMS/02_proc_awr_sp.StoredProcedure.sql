/****** Object:  StoredProcedure [dbo].[proc_awr_sp]    Script Date: 15/10/2019 15:23:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO


CREATE PROCEDURE [dbo].[proc_awr_sp](@p_begin_snap int, @p_end_snap int, @p_name_sp varchar(100))  with encryption
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
			total_elapsed_time float,
			total_elapsed_time_r float,
			total_worker_time float,
			total_worker_time_r float,
			total_logical_reads float,
			total_logical_reads_r float,
			total_logical_writes float,
			total_logical_writes_r float,
			total_physical_reads float,
			total_physical_reads_r float)
			
	declare @v_snap_id integer
	
	declare @sqlstatement NVARCHAR(4000)
	declare @v_d_end_interval_time datetime
	declare @v_d_snap_id integer
	declare @v_d_dbname varchar(50)
	declare @v_d_procname varchar(50)
	declare @v_d_cached_time datetime
	declare @v_d_exec_count float

	declare @vdelta_et float
	declare @vdelta_etr float
	declare @vdelta_wt float
	declare @vdelta_wtr float
	declare @vdelta_lr float
	declare @vdelta_lrr float
	declare @vdelta_lw float
	declare @vdelta_lwr float
	declare @vdelta_lp float
	declare @vdelta_lpr float

	declare @v_d_position integer
	declare @v_d_procid integer
	declare @v_tabla_date varchar(50)

	DECLARE c_snaphost CURSOR FOR 
	select snap_id
	from dba_hist_snapshot
	where snap_id between @p_begin_snap and @p_end_snap
	order by snap_id

	DECLARE c_tabla CURSOR FOR 
	select  distinct cast(end_interval_time as varchar(14)) as date
	from @t_tabletop
	order by date
	
			   
	print('-------------------------------------------------------------------------------------------------------')
	print('--'+upper(@p_name_sp)+'-----------------------------------------------------------------------------')
	print('-------------------------------------------------------------------------------------------------------')
	print('')
	
	open c_snaphost
	FETCH NEXT FROM c_snaphost INTO @v_snap_id
	
	WHILE @@FETCH_STATUS = 0  
	BEGIN
		set @sqlstatement = 'Declare c_snaphost_delta CURSOR GLOBAL FOR 
			select snap2.snap_id,snap2.end_interval_time,snap2.dbname,snap2.procname,snap2.cached_time,snap2.execution_count - isnull(snap1.execution_count,0) as vexec,
			(snap2.total_elapsed_time - isnull(snap1.total_elapsed_time,0))/1000000 as vdelta_et,
			cast(1.0*((snap2.total_elapsed_time - isnull(snap1.total_elapsed_time,0))/1000000)/(snap2.execution_count - isnull(snap1.execution_count,0)) as decimal(20,4)) as vdelta_etr,
			(snap2.total_worker_time - isnull(snap1.total_worker_time,0))/1000000 as vdelta_wt,
			cast(1.0*((snap2.total_worker_time - isnull(snap1.total_worker_time,0))/1000000)/(snap2.execution_count - isnull(snap1.execution_count,0)) as decimal(20,4)) as vdelta_wtr,
			(snap2.total_logical_reads - isnull(snap1.total_logical_reads,0)) as vdelta_lr,
			cast(1.0*((snap2.total_logical_reads - isnull(snap1.total_logical_reads,0)))/(snap2.execution_count - isnull(snap1.execution_count,0)) as decimal(20,4)) as vdelta_lrr,
			(snap2.total_logical_writes - isnull(snap1.total_logical_writes,0)) as vdelta_lw,
			cast(1.0*((snap2.total_logical_writes - isnull(snap1.total_logical_writes,0)))/(snap2.execution_count - isnull(snap1.execution_count,0)) as decimal(20,4)) as vdelta_lwr,
			(snap2.total_physical_reads - isnull(snap1.total_physical_reads,0)) as vdelta_pr,
			cast(1.0*((snap2.total_physical_reads - isnull(snap1.total_physical_reads,0)))/(snap2.execution_count - isnull(snap1.execution_count,0)) as decimal(20,4)) as vdelta_prr
			from 
			(select s.end_interval_time, s.snap_id, t.database_id as dbname, OBJECT_NAME(t.object_id, t.database_id) as procname,
			t.execution_count,t.cached_time,t.total_elapsed_time,t.total_logical_reads,t.total_logical_writes,t.total_physical_reads,total_worker_time
			from dba_hist_snapshot s, dba_hist_dm_exec_procedure_stats t
			where s.snap_id = t.snap_id and s.snap_id = '+ cast(@v_snap_id as varchar) +'
			and db_name(t.database_id) not in (''mdw'',''msdb'',''master'')
			and OBJECT_NAME(t.object_id, t.database_id) = ''' + @p_name_sp +''' ) snap2
			left outer join
			(select s.snap_id, t.database_id as dbname, OBJECT_NAME(t.object_id, t.database_id) as procname,
			t.execution_count,t.cached_time,t.total_elapsed_time,t.total_logical_reads,t.total_logical_writes,t.total_physical_reads,total_worker_time
			from dba_hist_snapshot s, dba_hist_dm_exec_procedure_stats t
			where s.snap_id = t.snap_id and s.snap_id = '+ cast((@v_snap_id - 1) as varchar) +'
			and db_name(t.database_id) not in (''mdw'',''msdb'',''master'')) snap1
			on snap1.dbname = snap2.dbname and snap1.procname = snap2.procname and snap1.cached_time = snap2.cached_time'
			
		exec sp_executesql @sqlstatement
		
		open c_snaphost_delta
		FETCH NEXT FROM c_snaphost_delta INTO @v_d_snap_id,@v_d_end_interval_time,@v_d_dbname,@v_d_procname,@v_d_cached_time,@v_d_exec_count,@vdelta_et,@vdelta_etr,@vdelta_wt,@vdelta_wtr,@vdelta_lr,@vdelta_lrr,@vdelta_lw,@vdelta_lwr,@vdelta_lp,@vdelta_lpr

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
						
			insert into @t_tabletop values(@v_d_end_interval_time,@v_d_position,@v_d_dbname,@v_d_procname,@v_d_cached_time,@v_d_exec_count,@vdelta_et,@vdelta_etr,@vdelta_wt,@vdelta_wtr,@vdelta_lr,@vdelta_lrr,@vdelta_lw,@vdelta_lwr,@vdelta_lp,@vdelta_lpr)
			set @v_d_position = @v_d_position + 1
		
			FETCH NEXT FROM c_snaphost_delta INTO @v_d_snap_id,@v_d_end_interval_time,@v_d_dbname,@v_d_procname,@v_d_cached_time,@v_d_exec_count,@vdelta_et,@vdelta_etr,@vdelta_wt,@vdelta_wtr,@vdelta_lr,@vdelta_lrr,@vdelta_lw,@vdelta_lwr,@vdelta_lp,@vdelta_lpr
		
		END
		
		CLOSE c_snaphost_delta
		DEALLOCATE c_snaphost_delta

		FETCH NEXT FROM c_snaphost INTO @v_snap_id
	END
		
	CLOSE c_snaphost
	DEALLOCATE c_snaphost

	select 
	CAST(replace(convert(varchar(16),end_interval_time,120),'-','') as varchar(15)) as snap_date,
	CAST(replace(convert(varchar(16),cached_time,120),'-','') as varchar(15)) as cached_time,
	CAST(execute_count as varchar(10)) as exec_count,
	CONVERT(varchar, CAST(total_elapsed_time AS money), 1) as elap_time,
	--CAST(format(total_elapsed_time,'###########0') as varchar(8)) as elap_time_old,
	CONVERT(varchar, CAST(total_elapsed_time_r AS numeric(18,3)), 1) as elap_time_r,
	--CAST(format(total_elapsed_time_r,'###########0.000') as varchar(8)) as elap_time_r_old, 
	CONVERT(varchar, CAST(total_worker_time AS numeric(18,2)), 1) as worker_time,
	--CAST(format(total_worker_time,'###########0') as varchar(8)) as worker_time_old,
	CONVERT(varchar, CAST(total_worker_time_r AS numeric(18,3)), 1) as worker_time_r,
	--CAST(format(total_worker_time_r,'###########0.000') as varchar(8)) as worker_time_r_old,
	CONVERT(varchar, CAST(total_logical_reads AS numeric(18,2)), 1) as logical_reads,
	--ªCAST(format(total_logical_reads,'###########0') as varchar(8)) as logical_reads_old,
	CONVERT(varchar, CAST(total_logical_reads_r AS numeric(18,3)), 1) as l_reads_r,
	--CAST(format(total_logical_reads_r,'###########0.000') as varchar(8)) as l_reads_r_old, 
	CONVERT(varchar, CAST(total_logical_writes AS numeric(18,2)), 1) as logical_writes,
	--CAST(format(total_logical_writes,'###########0') as varchar(8)) as logical_writes_old,
	CONVERT(varchar, CAST(total_logical_writes_r AS numeric(18,3)), 1) as l_writes_r,
	--CAST(format(total_logical_writes_r,'###########0.000') as varchar(8)) as l_writes_r_old, 
	CONVERT(varchar, CAST(total_physical_reads AS numeric(18,2)), 1) as physical_reads,
	--CAST(format(total_physical_reads,'###########0') as varchar(8)) as physical_reads_old,
	CONVERT(varchar, CAST(total_physical_reads_r AS numeric(18,3)), 1) as p_reads_r
	--CAST(format(total_physical_reads_r,'###########0.000') as varchar(8)) as p_reads_r_old 
	from @t_tabletop
	order by end_interval_time;

	
END;
GO
