/****** Object:  Table [dbo].[dba_hist_wait_class]    Script Date: 15/10/2019 15:26:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dba_hist_wait_class](
	[wait_class] [nvarchar](40) NOT NULL,
	[wait_type] [nvarchar](60) NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].dba_hist_wait_class ADD  CONSTRAINT [PK_dba_hist_wait_class] PRIMARY KEY CLUSTERED 
(
	[wait_class],[wait_type]
)ON [PRIMARY]
GO
