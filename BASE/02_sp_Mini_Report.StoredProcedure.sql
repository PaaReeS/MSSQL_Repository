create PROCEDURE [dbo].[sp_Mini_report]
AS
BEGIN
SET NOCOUNT ON;  
SET ARITHABORT ON;  
DECLARE @TableHTML  nvarchar(MAX)
set  @TableHTML=''
SELECT                                   
	@TableHTML = @TableHTML +                                                
	'<font face="Verdana" size="4" color="#008C95"><H3><bold>Estado de Bases de Datos</bold></H3></font><table style="BORDER-COLLAPSE: collapse" borderColor="#111111" cellPadding="0" width="100%" bgColor="#ffffff" borderColorLight="#000000" border="2">
	<tr>
	<th align="Center" width="50" bgColor="#008C95">
	<font face="Verdana" size="1" color="#FFFFFF">Servidor</font></th>
	<th align="Center" width="30" bgColor="#008C95">
	<font face="Verdana" size="1" color="#FFFFFF">Base de Datos</font></th>
	<th align="Center" width="120" bgColor="#008C95">
	<font face="Verdana" size="1" color="#FFFFFF">Estado</font></th>
	</tr>'             
SELECT                                   
@TableHTML =  @TableHTML +      
'<tr>
<td align="Center" ><font face="Verdana" size="1">' + ISNULL(CONVERT(nvarchar(100), @@servername  ), '')  +'</font></td>' +                                        
'<td align="Center" ><font face="Verdana" size="1">' + ISNULL(CONVERT(nvarchar(100), name ), '')  +'</font></td>' +                              
case when state_desc='ONLINE' then
'<td align="Center" ><font face="Verdana" size="1" color="#40C211"><b>' + ISNULL(CONVERT(nvarchar(100), state_desc ), '')  +'</font></td>'                              
else
'<td align="Center" ><font face="Verdana" size="1" color="#FF0000"><b>' + ISNULL(CONVERT(nvarchar(100), state_desc ), '')  +'</font></td>'                              
end
+'<tr>'
from sys.databases;
SELECT                                   
@TableHTML = @TableHTML + '</table>  '
select @TableHTML
end

