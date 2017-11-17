USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSIS_CourseCompletion]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Michael Osborn
-- Create date: 09/24/2013
-- Description:	Extract of CourseCompletion data where the SiteID from Course_Completion_Survey is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- =============================================
CREATE PROCEDURE [dbo].[SSIS_CourseCompletion]
	-- Add the parameters for the stored procedure here
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
		  ,[COURSE_COMPLETION_0_NAME111]
		  ,[COURSE_COMPLETION_0_DATE111]
		  ,[DW_AuditDate]
		  ,[DataSource]
		  ,[Master_SurveyID]
	FROM [DataWarehouse].[dbo].[Course_Completion_Survey]
	WHERE (SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
	or (SiteID = 78 and @ProfileID = 34))
	and ProgramID not in (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)
  
END
GO
