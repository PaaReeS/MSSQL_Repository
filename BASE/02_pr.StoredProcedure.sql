
create procedure pr
AS
BEGIN
SET NOCOUNT ON
DECLARE @proc TABLE (chk nvarchar(25),resultado NVARCHAR(75))
DECLARE @proc_res TABLE (resultado NVARCHAR(75))



insert into @proc_res 
exec proc_check_job;
insert into @proc 
select 'proc_check_job', resultado from @proc_res;
delete from @proc_res;

insert into @proc_res 
exec proc_check_lock;
insert into @proc 
select 'proc_check_lock', resultado from @proc_res;
delete from @proc_res;

insert into @proc_res 
exec proc_check_rdto;
insert into @proc 
select 'proc_check_rdto', resultado from @proc_res;
delete from @proc_res;

insert into @proc_res 
exec proc_check_db_status;
insert into @proc 
select 'proc_check_db_status', resultado from @proc_res;
delete from @proc_res;

select * from @proc


/* proc_check_job */
If ((select resultado from @proc where chk='proc_check_job')<>'OK')
select top 3 * from t_check_jobs_log order by 1 desc
/* proc_check_lock */
If ((select resultado from @proc where chk='proc_check_lock')<>'OK')
select top 3 * from t_check_proc_lock_log order by 1 desc
/* proc_check_rdto */
If ((select resultado from @proc where chk='proc_check_rdto')<>'OK')
select top 3 * from t_check_proc_rdto_log order by 1 desc
/* proc_check_db_status */
If ((select resultado from @proc where chk='proc_check_db_status')<>'OK')
select top 3 * from t_check_db_status_log order by 1 desc



END