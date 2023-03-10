
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[sp_par] with encryption
AS
BEGIN
	SET NOCOUNT ON;
	
	WITH t (keyid, clase, parametro, valor, parametro2, valor2, parentkeyid, lvl) 
	AS
	(
	SELECT keyid, clase, parametro,  valor, parametro2, valor2, parentkeyid, 1 AS lvl 
	FROM t_parametros WHERE parentkeyid IS NULL
	UNION ALL
	SELECT tp.keyid, tp.clase, tp.parametro, tp.valor, tp.parametro2, tp.valor2, tp.parentkeyid, t.lvl + 1 AS lvl FROM t_parametros AS tp INNER JOIN t ON t.keyid=tp.parentkeyid
	WHERE tp.parentkeyid IS NOT NULL
	)
	SELECT 
	cast(REPLICATE('-', lvl)+'> ' as nvarchar(5))
	+ ' '+ cast(t.keyid as nvarchar(4)) as keyid
	, cast(t.clase as nvarchar(15)) as clase
	, cast(t.parametro as nvarchar(15)) as parametro1
	, cast(t.valor as nvarchar(5)) as valor1
	, cast(t.parametro2 as nvarchar(15)) as parametro2
	, cast(t.valor2 as nvarchar(5)) as valor2
	, cast(case when lvl > 1 then parentkeyid else keyid end as nvarchar(5)) AS main
	--, cast(IIF (lvl > 1, parentkeyid, keyid) as nvarchar(5)) AS main
	FROM t ORDER BY keyid,lvl,parentkeyid;


END
GO
