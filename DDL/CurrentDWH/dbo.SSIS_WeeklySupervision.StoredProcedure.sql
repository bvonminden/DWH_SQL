USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSIS_WeeklySupervision]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Michael Osborn
-- Create date: 09/24/2013
-- Description:	Extract of WeeklySupervision data where the SiteID from [Weekly_Supervision_Survey] is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- =============================================
CREATE PROCEDURE [dbo].[SSIS_WeeklySupervision]
	@ProfileID INT 
AS
BEGIN
	
	SET NOCOUNT ON;
	
SELECT [SurveyResponseID]
      ,[ElementsProcessed]
      ,[SurveyID]
      ,[SurveyDate]
      ,[AuditDate]
      ,[CL_EN_GEN_ID]
      ,[SiteID]
      ,[ProgramID]
      ,[IA_StaffID]
      ,[ClientID]
      ,[RespondentID]
      ,[Entity_ID_Mapped]
      ,[NURSE_PERSONAL_0_NAME]
      ,[FORM_RECORD_0_COMPLETED_DATE]
      ,[NURSE_SUPERVISION_0_MIN]
      ,[DW_AuditDate]
      ,[NURSE_SUPERVISION_0_STAFF_SUP]
      ,[DataSource]
      ,[NURSE_SUPERVISION_0_STAFF_OTHER]
      ,[Master_SurveyID]
      ,[LastModified]
  FROM [DataWarehouse].[dbo].[Weekly_Supervision_Survey]
  WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
  AND ProgramID not in (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)

END
GO
