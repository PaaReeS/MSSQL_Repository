SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
USE [master]
GO
--Modoificamos FileGrowth
ALTER DATABASE [master] MODIFY FILE ( NAME = N'master', FILEGROWTH = 524288KB)
ALTER DATABASE [master] MODIFY FILE ( NAME = N'mastlog', FILEGROWTH = 131072KB)
ALTER DATABASE [model] MODIFY FILE ( NAME = N'modeldev', FILEGROWTH = 524288KB)
ALTER DATABASE [model] MODIFY FILE ( NAME = N'modellog', FILEGROWTH = 131072KB)
ALTER DATABASE [msdb] MODIFY FILE ( NAME = N'MSDBData', FILEGROWTH = 524288KB)
ALTER DATABASE [msdb] MODIFY FILE ( NAME = N'MSDBLog', FILEGROWTH = 131072KB)
GO
--Modificamos Size
IF((select COUNT(*) from sys.database_files where size<524288/8 and type=0)>0)
	ALTER DATABASE [master] MODIFY FILE ( NAME = N'master', SIZE = 524288KB)
IF((select COUNT(*) from sys.database_files where size<131072/8 and type=0)>0)
	ALTER DATABASE [master] MODIFY FILE ( NAME = N'mastlog', SIZE = 131072KB)
GO
USE [model]
GO
IF((select COUNT(*) from sys.database_files where size<524288/8 and type=0)>0)
	ALTER DATABASE [model] MODIFY FILE ( NAME = N'modeldev', SIZE = 524288KB)
IF((select COUNT(*) from sys.database_files where size<131072/8 and type=0)>0)
	ALTER DATABASE [model] MODIFY FILE ( NAME = N'modellog', SIZE = 131072KB) 
GO
USE [msdb]
GO
IF((select COUNT(*) from sys.database_files where size<524288/8 and type=0)>0)
	ALTER DATABASE [msdb] MODIFY FILE ( NAME = N'MSDBData', SIZE = 524288KB)
IF((select COUNT(*) from sys.database_files where size<131072/8 and type=0)>0)
	ALTER DATABASE [msdb] MODIFY FILE ( NAME = N'MSDBLog', SIZE = 131072KB)
GO
	
