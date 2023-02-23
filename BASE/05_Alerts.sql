--Alerts

USE [msdb]
GO

/****** Object:  Alert [Error Number 1105. Filegroup FULL]    Script Date: 04/03/2021 15:57:07 ******/
EXEC msdb.dbo.sp_add_alert @name=N'Error Number 1105. Filegroup FULL', 
		@message_id=1105, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=60, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Error Number 1105. Filegroup FULL', @operator_name=N'DBA', @notification_method = 1
GO

USE [msdb]
GO

/****** Object:  Alert [Error Number 823]    Script Date: 04/03/2021 15:57:43 ******/
EXEC msdb.dbo.sp_add_alert @name=N'Error Number 823', 
		@message_id=823, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=60, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Error Number 823', @operator_name=N'DBA', @notification_method = 1
GO



USE [msdb]
GO

/****** Object:  Alert [Error Number 824]    Script Date: 04/03/2021 15:58:09 ******/
EXEC msdb.dbo.sp_add_alert @name=N'Error Number 824', 
		@message_id=824, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=60, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Error Number 824', @operator_name=N'DBA', @notification_method = 1
GO


USE [msdb]
GO

/****** Object:  Alert [Error Number 825]    Script Date: 04/03/2021 15:59:02 ******/
EXEC msdb.dbo.sp_add_alert @name=N'Error Number 825', 
		@message_id=825, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=60, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Error Number 825', @operator_name=N'DBA', @notification_method = 1
GO

USE [msdb]
GO

/****** Object:  Alert [Error Number 9002. Transactional Log FULL]    Script Date: 04/03/2021 15:59:22 ******/
EXEC msdb.dbo.sp_add_alert @name=N'Error Number 9002. Transactional Log FULL', 
		@message_id=9002, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=60, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Error Number 9002. Transactional Log FULL', @operator_name=N'DBA', @notification_method = 1
GO

USE [msdb]
GO

/****** Object:  Alert [Severity 016]    Script Date: 04/03/2021 15:59:42 ******/
EXEC msdb.dbo.sp_add_alert @name=N'Severity 016', 
		@message_id=0, 
		@severity=16, 
		@enabled=1, 
		@delay_between_responses=60, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 016', @operator_name=N'DBA', @notification_method = 1
GO
USE [msdb]
GO

/****** Object:  Alert [Severity 017]    Script Date: 04/03/2021 16:00:04 ******/
EXEC msdb.dbo.sp_add_alert @name=N'Severity 017', 
		@message_id=0, 
		@severity=17, 
		@enabled=1, 
		@delay_between_responses=60, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 017', @operator_name=N'DBA', @notification_method = 1
GO

USE [msdb]
GO

/****** Object:  Alert [Severity 018]    Script Date: 04/03/2021 16:00:18 ******/
EXEC msdb.dbo.sp_add_alert @name=N'Severity 018', 
		@message_id=0, 
		@severity=18, 
		@enabled=1, 
		@delay_between_responses=60, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 018', @operator_name=N'DBA', @notification_method = 1
GO

USE [msdb]
GO

/****** Object:  Alert [Severity 019]    Script Date: 04/03/2021 16:01:07 ******/
EXEC msdb.dbo.sp_add_alert @name=N'Severity 019', 
		@message_id=0, 
		@severity=19, 
		@enabled=1, 
		@delay_between_responses=60, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 019', @operator_name=N'DBA', @notification_method = 1
GO


USE [msdb]
GO

/****** Object:  Alert [Severity 020]    Script Date: 04/03/2021 16:01:22 ******/
EXEC msdb.dbo.sp_add_alert @name=N'Severity 020', 
		@message_id=0, 
		@severity=20, 
		@enabled=1, 
		@delay_between_responses=60, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 020', @operator_name=N'DBA', @notification_method = 1
GO

USE [msdb]
GO

/****** Object:  Alert [Severity 021]    Script Date: 04/03/2021 16:02:32 ******/
EXEC msdb.dbo.sp_add_alert @name=N'Severity 021', 
		@message_id=0, 
		@severity=21, 
		@enabled=1, 
		@delay_between_responses=60, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 021', @operator_name=N'DBA', @notification_method = 1
GO

USE [msdb]
GO

/****** Object:  Alert [Severity 022 - Possible Corruption]    Script Date: 04/03/2021 16:02:42 ******/
EXEC msdb.dbo.sp_add_alert @name=N'Severity 022 - Possible Corruption', 
		@message_id=0, 
		@severity=22, 
		@enabled=1, 
		@delay_between_responses=60, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 022 - Possible Corruption', @operator_name=N'DBA', @notification_method = 1
GO

USE [msdb]
GO

/****** Object:  Alert [Severity 023 - Possible corruption]    Script Date: 04/03/2021 16:03:09 ******/
EXEC msdb.dbo.sp_add_alert @name=N'Severity 023 - Possible corruption', 
		@message_id=0, 
		@severity=23, 
		@enabled=1, 
		@delay_between_responses=60, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 023 - Possible Corruption', @operator_name=N'DBA', @notification_method = 1
GO

USE [msdb]
GO

/****** Object:  Alert [Severity 024]    Script Date: 04/03/2021 16:03:55 ******/
EXEC msdb.dbo.sp_add_alert @name=N'Severity 024', 
		@message_id=0, 
		@severity=24, 
		@enabled=1, 
		@delay_between_responses=60, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 024', @operator_name=N'DBA', @notification_method = 1
GO

USE [msdb]
GO

/****** Object:  Alert [Severity 025]    Script Date: 04/03/2021 16:10:24 ******/
EXEC msdb.dbo.sp_add_alert @name=N'Severity 025', 
		@message_id=0, 
		@severity=25, 
		@enabled=1, 
		@delay_between_responses=60, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 025', @operator_name=N'DBA', @notification_method = 1
GO

USE [msdb]
GO
EXEC msdb.dbo.sp_add_alert @name=N'Error Number 829', 
@message_id=829, 
@severity=0, 
@enabled=1, 
@delay_between_responses=60, 
@include_event_description_in=1
--,@job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Error Number 829', @operator_name=N'DBA', @notification_method = 1
GO
