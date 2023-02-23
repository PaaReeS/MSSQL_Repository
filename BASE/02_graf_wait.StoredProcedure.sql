create procedure graf_WAIT with encryption
as
begin
declare @snap_id int = (select max(snap_id) from dba_hist_snapshot);
	
select top 5
replace(snap2.wait_class,' ','_') as wait_class
, cast((snap2.wait_time_ms-snap1.wait_time_ms)/1000.00 as decimal(15,2)) wait_time_ms
from(
	select 
	s.snap_id
	, c.wait_class
	, sum(dm.wait_time_ms) wait_time_ms
	from dba_hist_dm_os_wait_stats dm
		join dba_hist_snapshot s
			on dm.snap_id=s.snap_id
		left outer join dba_hist_wait_class c
			on dm.wait_type=c.wait_type
	where upper(c.wait_class) not in ('IGNORE','SIN_GRUPO', 'OTHER')
	and s.snap_id = @snap_id 
	group by s.snap_id,wait_class
	) snap2
	join
	(
	select 
	s.snap_id
	, c.wait_class
	, sum(dm.wait_time_ms) wait_time_ms
	from dba_hist_dm_os_wait_stats dm
		join dba_hist_snapshot s
			on dm.snap_id=s.snap_id
		left outer join dba_hist_wait_class c
			on dm.wait_type=c.wait_type
	where upper(c.wait_class) not in ('IGNORE','SIN_GRUPO', 'OTHER')
	and s.snap_id = @snap_id -1
	group by s.snap_id,wait_class
	) snap1
		on snap1.wait_class = snap2.wait_class
	order by 2 desc
end;
go