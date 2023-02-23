/****** object:  table [dbo].[t_parametros]    script date: 15/10/2019 15:26:28 ******/
set ansi_nulls on
go
set quoted_identifier on
go
create table [dbo].[t_parametros](
	[keyid] [int] NOT null,
	[clase] [nvarchar](50) null,
	[parametro] [nvarchar](50) null,
	[valor] [nvarchar](50) null,
	[parametro2] [nvarchar](50) null,
	[valor2] [nvarchar](50) null,
	[comentario] [nvarchar](50) null,
	[parentkeyid] [int] null
) 
go
ALTER TABLE [dbo].t_parametros ADD  CONSTRAINT [PK_t_parametros] PRIMARY KEY CLUSTERED 
(
	[keyid]
)ON [PRIMARY]
GO

