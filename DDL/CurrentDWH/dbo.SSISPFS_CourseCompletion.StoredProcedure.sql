USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISPFS_CourseCompletion]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Create date: 1/12/2016
-- Description:	Extract of CourseCompletion data where the SiteID from Course_Completion_Survey is the
--				same as ExportPFSEntities SiteID and ExportProfileID is the same as the passed ProfileID
--				for Pay For Success where clients are over the age of 14
-- =============================================
CREATE PROCEDURE [dbo].[SSISPFS_CourseCompletion]
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
	WHERE SiteID IN (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities 
					   WHERE ExportProfileID = @ProfileID)
  
END

GO
