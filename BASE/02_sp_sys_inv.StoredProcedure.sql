create procedure sp_sys_inv with encryption
AS
BEGIN
SELECT @@SERVERNAME,name,sysadmin,securityadmin,serveradmin,setupadmin,processadmin,diskadmin,denylogin,hasaccess 
FROM sys.syslogins
where  sysadmin=1
and name not like ('%gmsa%')
and name not like ('%SQLAgent$%')
and name not like ('%MSSQL$%')
and name not in ('NT SERVICE\MSSQLSERVER','NT SERVICE\SQLSERVERAGENT','NT SERVICE\SQLWriter','NT SERVICE\Winmgmt')
order by sysadmin  desc
END