/****** Object:  StoredProcedure [dbo].[proc_check_job]    Script Date: 15/10/2019 15:23:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[proc_check_job] with encryption
AS
BEGIN
	set nocount on
	declare @c_owner nvarchar(100)
	declare @c_job_name nvarchar(100)
	declare @c_limit_failures integer
	declare @c_level_inc nvarchar(100)
	declare @c_interval_min integer
	declare @res nvarchar(1000)
	declare @v_level nvarchar(100)
	declare @v_enabled integer
	declare @v_job_name nvarchar(500);
	declare @v_last_status integer
	declare @v_exists integer

	select @res = 'OK', @v_level = 'OK', @v_job_name = ''; 
	DECLARE c_job CURSOR FOR select owner,job_name,limit_failures,level_inc,interval_min from t_check_jobs	where enabled = 'S'	and (fecha_fin_exclusion is null or fecha_fin_exclusion < SYSDATETIME());

	OPEN c_job
	FETCH NEXT FROM c_job INTO @c_owner,@c_job_name, @c_limit_failures, @c_level_inc, @c_interval_min
	
	WHILE @@FETCH_STATUS = 0  
	BEGIN  
		select @v_enabled = -1 
		select @v_enabled = enabled from msdb.dbo.sysjobs where name = @c_job_name
		IF @v_enabled = -1 --No existe el job
		begin
			set @v_level = @c_level_inc
			set @v_job_name =@v_job_name + '#' + @c_job_name;
			insert into t_check_jobs_log (load_date, owner, job_name, level_inc, error_text) VALUES (sysdatetime(), @c_owner, @c_job_name, @c_level_inc, 'Errores de planificacion. No existe el job.')
		end
		if @v_enabled  = 0 --Deshabilitado
		begin
			set @v_level = @c_level_inc
			set @v_job_name = @v_job_name + '#' + @c_job_name;
			insert into t_check_jobs_log (load_date, owner, job_name, level_inc, error_text)
			VALUES (sysdatetime(), @c_owner, @c_job_name, @c_level_inc, 'El job no está habilitado.')
		end
		if @v_enabled  = 1 --Habilitado
		begin
			set @v_exists = 0
			select top 1 @v_exists = 1,  @v_last_status = h.run_status
			from msdb.dbo.sysjobs j
				join msdb.dbo.sysjobhistory h
					on j.job_id = h.job_id
			where j.name =@c_job_name and h.step_id = 0
			and msdb.dbo.agent_datetime(run_date, run_time) > DATEADD(minute, -1 * @c_interval_min, sysdatetime())
			order by msdb.dbo.agent_datetime(run_date, run_time) desc
			
			if (@v_exists = 1)
			begin
				if @v_last_status = 0 --Fallo en ejecuccion
				begin
					if((ISNULL(@c_limit_failures, 1)) > (select count(1) from (select top (isnull(@c_limit_failures,1)) h.run_status,msdb.dbo.agent_datetime(run_date, run_time) as date from msdb.dbo.sysjobs j join msdb.dbo.sysjobhistory h	on j.job_id = h.job_id	where j.name =@c_job_name and h.step_id = 0 order by msdb.dbo.agent_datetime(run_date, run_time) desc ) as a where run_status=0))
					BEGIN
					set @v_level = @v_level
					END
					else
					begin					
						set @v_level = @c_level_inc
						set @v_job_name = @v_job_name + '#' + @c_job_name
						insert into t_check_jobs_log (load_date, owner, job_name, level_inc, error_text) VALUES (sysdatetime(), @c_owner, @c_job_name, @c_level_inc, 'Fallo en la ejecucion.')
					end
				end
			end
			else
			begin
				set @v_level = @c_level_inc;
				set @v_job_name = @v_job_name + '#' + @c_job_name;
				insert into t_check_jobs_log (load_date, owner, job_name, level_inc, error_text) VALUES (sysdatetime(), @c_owner, @c_job_name, @c_level_inc, 'No existe registro de ejecución en el intervalo revisado.')
			end
		end
		FETCH NEXT FROM c_job INTO @c_owner, @c_job_name, @c_limit_failures, @c_level_inc, @c_interval_min
	END 
	
	CLOSE c_job  
	DEALLOCATE c_job 
	
	if (@v_level <> 'OK')
		set @res = @v_level+' '+@v_job_name

	select @res
END

GO
