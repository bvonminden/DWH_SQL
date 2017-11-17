USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISPFS_NewHire]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Sheri Scott
-- Create date: 1/13/2016
-- Description:	Extract of NewHire data where the SiteID from New_Hire_Survey is the
--				same as ExportPFSEntities SiteID and ExportProfileID is the same as the passed ProfileID
--				for Pay For Success where clients are over the age of 14
-- =============================================
CREATE PROCEDURE [dbo].[SSISPFS_NewHire]
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
      ,[NEW_HIRE_0_HIRE_DATE]
      ,[NEW_HIRE_1_NAME_FIRST]
      ,[NEW_HIRE_0_NAME_LAST]
      ,[NEW_HIRE_1_ROLE]
      ,[NEW_HIRE_ADDRESS_1_STREET]
      ,[NEW_HIRE_ADDRESS_1_CITY]
      ,[NEW_HIRE_ADDRESS_1_STATE]
      ,[NEW_HIRE_ADDRESS_0_ZIP]
      ,[NEW_HIRE_0_PHONE]
      ,[NEW_HIRE_0_EMAIL]
      ,[NEW_HIRE_SUP_0_PHONE]
      ,[NEW_HIRE_SUP_0_EMAIL]
      ,[NEW_HIRE_0_REASON_FOR_HIRE]
      ,[NEW_HIRE_0_REASON_FOR_HIRE_REPLACE]
      ,[NEW_HIRE_0_FTE]
      ,[NEW_HIRE_0_PREVIOUS_NFP_WORK]
      ,[NEW_HIRE_0_REASON_NFP_WORK_DESC]
      ,[NEW_HIRE_0_EDUC_COMPLETED]
      ,[NEW_HIRE_0_START_DATE]
      ,[NEW_HIRE_SUP_0_NAME]
      ,[NEW_HIRE_0_TEAM_NAME]
      ,[NEW_HIRE_0_ACCESS_LEVEL]
      ,[DISP_CODE]
      ,[REVIEWED_BY]
      ,[REVIEWED_DATE]
      ,[ADDED_TO_ETO]
      ,[ADDED_TO_ETO_BY]
      ,[ETO_LOGIN_EMAILED]
      ,[ETO_LOGIN_EMAILED_BY]
      ,[ADDED_TO_CMS]
      ,[ADDED_TO_CMS_BY]
      ,[GEN_COMMENTS]
      ,[CHANGE_STATUS_COMPLETED]
      ,[NEW_HIRE_1_DOB]
      ,[NEW_HIRE_1_PREVIOUS_WORK_AGENCY]
      ,[NEW_HIRE_1_PREVIOUS_WORK_CITY]
      ,[NEW_HIRE_1_PREVIOUS_WORK_DATE1]
      ,[NEW_HIRE_1_PREVIOUS_WORK_DATE2]
      ,[NEW_HIRE_1_PREVIOUS_WORK_NAME]
      ,[NEW_HIRE_1_PREVIOUS_WORK_STATE]
      ,[NEW_HIRE_1_REPLACE_STAFF_TERM]
      ,[NEW_HIRE_ER_0_LNAME]
      ,[NEW_HIRE_ER_1_FNAME]
      ,[NEW_HIRE_ER_1_PHONE]
      ,[NEW_HIRE_ADDRESS_1_STATE_OTHR]
      ,[NEW_HIRE_SUP_0_NAME_OTHR]
      ,[DW_AuditDate]
      ,[DataSource]
      ,[NEW_HIRE_ADDITIONAL_INFO]
      ,[Master_SurveyID]
  FROM [DataWarehouse].[dbo].[New_Hire_Survey]
  WHERE SiteID IN (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities 
					WHERE ExportProfileID = @ProfileID)
  
END

GO
