USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISPFS_EducationRegistration]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Create date: 1/12/2016
-- Description:	Extract of EducationRegistration data where the SiteID from [Education_Registration_Survey] is the
--				same as ExportPFSEntities SiteID and ExportProfileID is the same as the passed ProfileID
--				for Pay For Success where clients are over the age of 14
-- =============================================
CREATE PROCEDURE [dbo].[SSISPFS_EducationRegistration]
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
  FROM [DataWarehouse].[dbo].[Education_Registration_Survey]
  WHERE SiteID IN (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities 
				   WHERE ExportProfileID = @ProfileID)

END

GO
