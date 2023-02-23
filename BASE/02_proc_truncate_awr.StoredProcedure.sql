SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure proc_truncate_awr with encryption
as
begin
set nocount on
declare @v_day integer
declare @v_snap integer
set @v_day = (select valor from t_parametros where keyid=50);
set @v_snap=(select max(snap_id) from dba_hist_snapshot  where CONVERT(VARCHAR(10), end_interval_time, 111) = CONVERT(VARCHAR(10), getdate()-@v_day, 111));


delete from dba_hist_dm_exec_procedure_stats where snap_id < @v_snap ;
delete from dba_hist_dm_io_virtual_file_stats where snap_id < @v_snap ;
delete from dba_hist_dm_os_sys_info where snap_id < @v_snap ;
delete from dba_hist_dm_os_sys_memory where snap_id < @v_snap ;
delete from dba_hist_dm_os_wait_stats where snap_id < @v_snap ;
--graficas
delete from dba_hist_graf_users where end_interval_time < getdate()- (select valor from t_parametros where keyid=50);--Mismo parametro que awr
end
go

