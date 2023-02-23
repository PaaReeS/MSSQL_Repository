create procedure graf_USERS with encryption
as
begin
set nocount on

declare @date datetime
set @date=(select getdate())

SELECT distinct
DB_NAME(sp.dbid) AS db
,(select COUNT(spid) from sys.sysprocesses where dbid > 0 and dbid=sp.dbid) as Total
,(select COUNT(spid) from sys.sysprocesses where dbid > 0 and dbid=sp.dbid and upper(status)='DORMANT') as Dormant 
,(select COUNT(spid) from sys.sysprocesses where dbid > 0 and dbid=sp.dbid and upper(status)='RUNNING') as Running
,(select COUNT(spid) from sys.sysprocesses where dbid > 0 and dbid=sp.dbid and upper(status)='BACKGROUND') as Background
,(select COUNT(spid) from sys.sysprocesses where dbid > 0 and dbid=sp.dbid and upper(status)='ROLLBACK')  as [Rollback]
,(select COUNT(spid) from sys.sysprocesses where dbid > 0 and dbid=sp.dbid and upper(status)='PENDING')  as Pending
,(select COUNT(spid) from sys.sysprocesses where dbid > 0 and dbid=sp.dbid and upper(status)='RUNNABLE')  as Runnable
,(select COUNT(spid) from sys.sysprocesses where dbid > 0 and dbid=sp.dbid and upper(status)='SPINLOOP') as Spinloop
,(select COUNT(spid) from sys.sysprocesses where dbid > 0 and dbid=sp.dbid and upper(status)='SUSPENDED') as Suspended
,(select COUNT(spid) from sys.sysprocesses where dbid > 0 and dbid=sp.dbid and upper(status)='SLEEPING')as Sleeping
into #tablatemporal
from(select distinct dbid
FROM sys.sysprocesses  where dbid > 0 ) sp


select * from #tablatemporal
insert into dba_hist_graf_users select @date,db,Total,Dormant,Running,Background,[Rollback],Pending,Runnable,Spinloop,Suspended,Sleeping from #tablatemporal

end;
go