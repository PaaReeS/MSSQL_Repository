create procedure proc_lock
as
begin
select  distinct
sysdatetime() as date
, db_name(blocked.database_id) as database_name
, ec.session_id as spid_blocking_session 
, sess.login_name as login_blocking_session
, sess.host_name as host_blocking_session
, ec.client_net_address as ip_blocking_session
, blocked.session_id as spid_blocked_session
, sess2.login_name as login_blocked_session
, sess2.host_name as host_blocked_session
, ec2.client_net_address as ip_blocked_session
, cast(round(blocked.wait_time/ 1000,2,0) as decimal(10))  as lce_blocked_session_sec--,cast(round(r.wait_time / 1000,2,0) as decimal(10)) 'waittime (sec)' --,cast(round(r.total_elapsed_time / (1000.0),2,0) as decimal(10)) 'lce (sec)'
, blocked.wait_type as wait_type
, blocked.wait_resource as wait_resource
, blockingsql.text as blocking_text
, blockedsql.text as blocked_text
,dateadd(second,blocked.estimated_completion_time/1000, getdate()) as "estimated completion time"
from sys.dm_exec_connections as ec  --55
	join sys.dm_exec_requests as blocked --68
		on ec.session_id = blocked.blocking_session_id
	join sys.dm_os_waiting_tasks as waits 
		on blocked.session_id = waits.session_id
	join sys.dm_exec_sessions sess  --55
		on ec.session_id = sess.session_id
	join sys.dm_exec_sessions sess2  --68
		on blocked.session_id = sess2.session_id
	join sys.dm_exec_connections as ec2
		on ec2.session_id = blocked.session_id
	cross apply sys.dm_exec_sql_text(ec.most_recent_sql_handle) as blockingsql
	cross apply sys.dm_exec_sql_text(blocked.sql_handle) as blockedsql
	order by lce_blocked_session_sec
	end