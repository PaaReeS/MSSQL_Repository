create procedure graf_MEM with encryption
as
begin
select 
convert(decimal(18,2),100.00 - (100.00*(available_physical_memory_kb/1.00)/(total_physical_memory_kb/1.00)),1) as Percentage_used
--, (total_physical_memory_kb - available_physical_memory_kb)/1024 as MB_Used
--, available_physical_memory_kb/1024 MB_Available
--, total_physical_memory_kb/1024 MB_Total
from sys.dm_os_sys_memory
end;
go