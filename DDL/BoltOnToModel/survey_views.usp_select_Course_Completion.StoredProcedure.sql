DROP PROCEDURE [survey_views].[usp_select_Course_Completion]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_Course_Completion] as  begin  select * from survey_views.Course_Completion end 
GO
