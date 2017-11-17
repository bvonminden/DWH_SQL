USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSIS_EducationRegistration]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Michael Osborn
-- Create date: 09/24/2013
-- Description:	Extract of EducationRegistration data where the SiteID from [Education_Registration_Survey] is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- =============================================
CREATE PROCEDURE [dbo].[SSIS_EducationRegistration]
	-- Add the parameters for the stored procedure here
	@ProfileID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
--DECLARE @ProfileID INT --Testing
--SET @ProfileID = 27    --Testing

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
		  ,[Validation_Ind]
		  ,[Validation_Comment]
		  ,[Entity_ID_Mapped]
		  ,[EDUC_REGISTER_0_REASON]
		  ,[First_Confirmation_Sent]
		  ,[First_Confirmation_Sent_By]
		  ,[Second_Confirmation_Sent]
		  ,[Second_Confirmation_Sent_By]
		  ,[Third_Confirmation_Sent]
		  ,[Third_Confirmation_Sent_By]
		  ,[Materials_Shipped]
		  ,[Materials_Shipped_By]
		  ,[Disposition]
		  ,[Disposition_Text]
		  ,[Comments]
		  ,[ClassName]
		  ,[LMS_ClassID]
		  ,[LMS_CourseID]
		  ,[ClassName_Changed_To]
		  ,[Invoice_Nbr]
		  ,[DW_AuditDate]
		  ,[DataSource]
		  ,[Master_SurveyID]
		  ,[LastModified]
	  FROM [DataWarehouse].[dbo].[Education_Registration_Survey] s
	  WHERE SiteID IN (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
	  AND ProgramID NOT IN (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)
	  
END
GO
