DROP PROCEDURE [survey_views].[usp_select_MN_Primary_Caregiver_Intake]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [survey_views].[usp_select_MN_Primary_Caregiver_Intake] as  begin  select * from survey_views.MN_Primary_Caregiver_Intake end 
GO
