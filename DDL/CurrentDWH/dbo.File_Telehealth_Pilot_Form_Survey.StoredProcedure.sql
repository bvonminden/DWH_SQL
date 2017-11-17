USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[File_Telehealth_Pilot_Form_Survey]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[File_Telehealth_Pilot_Form_Survey]
	-- Add the parameters for the stored procedure here
	@SiteID INT
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
      ,[Master_SurveyID]
      ,[SurveyDate]
      ,[AuditDate]
      ,[CL_EN_GEN_ID]
      ,[SiteID]
      ,[ProgramID]
      ,[IA_StaffID]
      ,[ClientID]
      ,[RespondentID]
      ,[DW_AuditDate]
      ,[DataSource]
      ,[CLIENT_TELEHEALTH_REASON]
      ,[CLIENT_TELEHEALTH_TYPE]
      ,[CLIENT_0_ID_NSO]
      ,[CLIENT_PERSONAL_0_NAME_FIRST]
      ,[CLIENT_PERSONAL_0_NAME_LAST]
      ,[CLIENT_TELEHEALTH_REASON_OTHER]
      ,[CLIENT_TELEHEALTH_TYPE_OTHER]
      ,[CLIENT_PERSONAL_0_DOB_INTAKE]
      ,[NURSE_PERSONAL_0_NAME]
      ,[LastModified]
      ,[Archive_Record]
  FROM [DataWarehouse].[dbo].[Telehealth_Pilot_Form_Survey]
  WHERE SiteID IN(@SiteID)
END

GO
