DROP PROCEDURE [survey_views].[usp_select_Weekly_Supervision_Record]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_Weekly_Supervision_Record] as  begin  select * from survey_views.Weekly_Supervision_Record end 
GO
